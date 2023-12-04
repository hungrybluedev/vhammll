// cross_validate.v
module vhammll

import strconv
import runtime
import rand

// cross_validate performs n-fold cross-validation on a dataset: it
// partitions the instances in a dataset into a fold, trains
// a classifier on all the dataset instances not in the fold, and
// then uses this classifier to classify the fold instances. This
// process is repeated for each of n folds, and the classification
// results are summarized.
// ```sh
// Options (also see the Options struct):
// bins: range for binning or slicing of continuous attributes;
// number_of_attributes: the number of attributes to use, in descending
// 	order of rank value;
// exclude_flag: excludes missing values when ranking attributes;
// weighting_flag: nearest neighbor counts are weighted by
// 	class prevalences;
// folds: number of folds n to use for n-fold cross-validation (default
// 	is leave-one-out cross-validation);
// repetitions: number of times to repeat n-fold cross-validations;
// random-pick: choose instances randomly for n-fold cross-validations.
// Output options:
// show_flag: prints results to the console;
// expanded_flag: prints additional information to the console, including
// 	a confusion matrix.
// outputfile_path: saves the result as a json file.
// ```
pub fn cross_validate(ds Dataset, opts Options) CrossVerifyResult {
	println('ds.class_counts in cross_validate.v: ${ds.class_counts}')
	// to sort out what is going on, run the test file with concurrency off.
	mut cross_opts := opts
	cross_opts.datafile_path = ds.path
	mut total_instances := ds.Class.class_values.len

	repeats := if opts.repetitions == 0 { 1 } else { opts.repetitions }
	// for each class, instantiate an entry in the confusion matrix map
	mut confusion_matrix_map := map[string]map[string]f64{}
	for key1, _ in ds.class_counts {
		for key2, _ in ds.class_counts {
			confusion_matrix_map[key2][key1] = 0
		}
	}
	if opts.multiple_flag {
		cross_opts.MultipleClassifiersArray = read_multiple_opts(cross_opts.multiple_classify_options_file_path) or {
			panic('read_multiple_opts failed')
		}
		cross_opts.break_on_all_flag = opts.break_on_all_flag
		cross_opts.combined_radii_flag = opts.combined_radii_flag
		// cross_opts.classifier_indices = opts.classifier_indices
		if opts.classifier_indices == [] {
			cross_opts.classifier_indices = []int{len: cross_opts.multiple_classifiers.len, init: index}
		} else {
			cross_opts.classifier_indices = opts.classifier_indices
		}
	}
	// println(cross_opts.classifier_indices)
	// instantiate a struct for the result
	mut inferences_map := map[string]int{}
	for key, _ in ds.class_counts {
		inferences_map[key] = 0
	}
	mut cross_result := CrossVerifyResult{
		LoadOptions: ds.LoadOptions
		datafile_path: ds.path
		multiple_classify_options_file_path: cross_opts.multiple_classify_options_file_path
		labeled_classes: ds.class_values
		class_counts: ds.class_counts
		classes: ds.classes
		pos_neg_classes: get_pos_neg_classes(ds.class_counts)
		confusion_matrix_map: confusion_matrix_map
		repetitions: cross_opts.repetitions
		correct_inferences: inferences_map.clone()
		incorrect_inferences: inferences_map.clone()
		wrong_inferences: inferences_map.clone()
		true_positives: inferences_map.clone()
		true_negatives: inferences_map.clone()
		false_positives: inferences_map.clone()
		false_negatives: inferences_map.clone()
		Parameters: cross_opts.Parameters
		DisplaySettings: cross_opts.DisplaySettings
		MultipleOptions: cross_opts.MultipleOptions
		MultipleClassifiersArray: cross_opts.MultipleClassifiersArray
	}

	// if there are no useful continuous attributes, set binning to 0
	if ds.useful_continuous_attributes.len == 0 {
		cross_opts.bins = [0]
	}
	cross_result.binning = get_binning(cross_opts.bins)
	mut repetition_result := CrossVerifyResult{}
	for rep in 0 .. repeats {
		// generate a pick list of indices
		mut pick_list := []int{}
		if opts.random_pick {
			mut n := 0
			for pick_list.len < total_instances {
				n = rand.int_in_range(0, total_instances) or { 0 }
				if n in pick_list {
					continue
				}
				pick_list << n
			}
		} else {
			for i in 0 .. total_instances {
				pick_list << i
			}
		}
		repetition_result = do_repetition(pick_list, rep, ds, cross_opts) or { panic(err) }

		cross_result.inferred_classes << repetition_result.inferred_classes
		cross_result.actual_classes << repetition_result.actual_classes
		cross_result.binning = repetition_result.binning
		cross_result.classifier_instances_counts << repetition_result.classifier_instances_counts
		cross_result.prepurge_instances_counts_array << repetition_result.prepurge_instances_counts_array
		cross_result.maximum_hamming_distance = repetition_result.maximum_hamming_distance
	}
	cross_result = summarize_results(repeats, mut cross_result)
	cross_result.Metrics = get_metrics(cross_result)
	// println('cross_result.pos_neg_classes: $cross_result.pos_neg_classes')
	if cross_result.pos_neg_classes.len == 2 {
		cross_result.BinaryMetrics = get_binary_stats(cross_result)
	}
	if opts.command == 'cross' && (opts.show_flag || opts.expanded_flag) {
		show_crossvalidation(cross_result, opts)
	}
	if opts.outputfile_path != '' {
		save_json_file(cross_result, opts.outputfile_path)
	}
	if !opts.multiple_flag && opts.append_settings_flag && opts.command == 'cross' {
		append_cross_settings_to_file(cross_result, opts)
	}
	return cross_result
}

// append_cross_settings_to_file
fn append_cross_settings_to_file(result CrossVerifyResult, opts Options) {
	// println(result)
	append_json_file(ClassifierSettings{
		classifier_options: result.Parameters
		binary_metrics: result.BinaryMetrics
	}, opts.settingsfile_path)
}

// do_repetition
fn do_repetition(pick_list []int, rep int, ds Dataset, cross_opts Options) ?CrossVerifyResult {
	mut fold_result := CrossVerifyResult{}
	// instantiate a struct for the result
	mut repetition_result := CrossVerifyResult{}
	// test if leave-one-out crossvalidation is requested
	folds := if cross_opts.folds == 0 { ds.class_values.len } else { cross_opts.folds }
	// if the concurrency flag is set
	if cross_opts.concurrency_flag {
		// we are not implementing this for multiple classifiers
		mut result_channel := chan CrossVerifyResult{cap: folds}
		// queue all work + the sentinel values:
		jobs := runtime.nr_jobs()
		mut work_channel := chan int{cap: folds + jobs}
		for i in 0 .. folds {
			work_channel <- i
		}
		for _ in 0 .. jobs {
			work_channel <- -1
		}
		// start a thread pool to do the work:
		mut tpool := []thread{}
		for _ in 0 .. jobs {
			tpool << spawn option_worker(work_channel, result_channel, pick_list, folds,
				ds, cross_opts)
		}
		tpool.wait()
		//
		for _ in 0 .. folds {
			fold_result = <-result_channel
			// println(summarize_results(1, mut fold_result).incorrects_count)
			repetition_result.inferred_classes << fold_result.inferred_classes
			repetition_result.actual_classes << fold_result.labeled_classes
			repetition_result.binning = fold_result.binning
			repetition_result.classifier_instances_counts << fold_result.classifier_instances_counts
			repetition_result.prepurge_instances_counts_array << fold_result.prepurge_instances_counts_array
		}
	} else {
		// for each fold
		for current_fold in 0 .. folds {
			fold_result = do_one_fold(pick_list, current_fold, folds, ds, cross_opts)
			repetition_result.inferred_classes << fold_result.inferred_classes
			repetition_result.actual_classes << fold_result.labeled_classes
			repetition_result.binning = fold_result.binning
			repetition_result.classifier_instances_counts << fold_result.classifier_instances_counts
			repetition_result.prepurge_instances_counts_array << fold_result.prepurge_instances_counts_array
			repetition_result.maximum_hamming_distance = fold_result.maximum_hamming_distance
		}
	}
	// println('repetition_result.maximum_hamming_distance: ${repetition_result.maximum_hamming_distance}')
	// println(arrays.sum(repetition_result.classifier_instances_counts) or {0} / f64(repetition_result.classifier_instances_counts.len))
	return repetition_result
}

// summarize_results
fn summarize_results(repeats int, mut result CrossVerifyResult) CrossVerifyResult {
	// println(result.classifier_instances_counts)
	mut inferred := ''
	for i, actual in result.actual_classes {
		inferred = result.inferred_classes[i]

		result.labeled_instances[actual] += 1
		result.total_count += 1
		if inferred != '' {
			result.confusion_matrix_map[actual][inferred] += 1
		}
		if actual == inferred {
			result.correct_inferences[actual] += 1
			result.correct_count += 1
			result.true_positives[actual] += 1
		} else {
			if inferred != '' {
				result.wrong_inferences[inferred] += 1
				result.false_positives[inferred] += 1
			}
			result.incorrect_inferences[actual] += 1
			result.false_negatives[actual] += 1
			result.incorrects_count += 1
			result.wrong_count += 1
		}
	}
	if repeats > 1 {
		result.correct_count /= repeats
		result.incorrects_count /= repeats
		result.wrong_count /= repeats
		result.total_count /= repeats

		for _, mut v in result.labeled_instances {
			v /= f64(repeats)
		}
		for _, mut v in result.correct_inferences {
			v /= f64(repeats)
		}
		for _, mut v in result.incorrect_inferences {
			v /= f64(repeats)
		}
		for _, mut v in result.wrong_inferences {
			v /= f64(repeats)
		}
		for _, mut v in result.true_positives {
			v /= f64(repeats)
		}
		for _, mut v in result.false_positives {
			v /= f64(repeats)
		}
		for _, mut v in result.false_negatives {
			v /= f64(repeats)
		}

		for _, mut m in result.confusion_matrix_map {
			for _, mut v in m {
				v /= f64(repeats)
			}
		}
	}
	return result
}

// div_map
fn div_map(n int, mut m map[string]int) map[string]int {
	for _, mut a in m {
		a /= n
	}
	return m
}

// do_one_fold
fn do_one_fold(pick_list []int, current_fold int, folds int, ds Dataset, cross_opts Options) CrossVerifyResult {
	// println('cross_opts in do_one_fold: ${cross_opts}')
	mut byte_values_array := [][]u8{}
	// partition the dataset into a partial dataset and a fold
	mut part_ds, fold := partition(pick_list, current_fold, folds, ds, cross_opts)
	// println('fold in do_one_fold: $fold')
	mut fold_result := CrossVerifyResult{
		labeled_classes: fold.class_values
		instance_indices: fold.indices
	}
	if !cross_opts.multiple_flag {
		part_cl := make_classifier(mut part_ds, cross_opts)
		// println('part_cl.maximum_hamming_distance: ${part_cl.maximum_hamming_distance}')
		fold_result.binning = part_cl.binning
		fold_result.maximum_hamming_distance = part_cl.maximum_hamming_distance

		fold_result.classifier_instances_counts << part_cl.instances.len
		fold_result.prepurge_instances_counts_array << part_cl.history[0].prepurge_instances_count
		for attr in part_cl.attribute_ordering {
			// get the index of the corresponding attribute in the fold
			j := fold.attribute_names.index(attr)
			// create byte_values for the fold data
			byte_values_array << process_fold_data(part_cl.trained_attributes[attr], fold.data[j])
		}
		fold_instances := transpose(byte_values_array)
		// for each class, instantiate an entry in the class table for the result
		// note that this needs to use the classes in the partition portion, not
		// the fold, so that wrong inferences get recorded properly.
		mut confusion_matrix_row := map[string]int{}
		// for each class, instantiate an entry in the confusion matrix row
		for key, _ in ds.Class.class_counts {
			confusion_matrix_row[key] = 0
		}
		fold_result = classify_in_cross(part_cl, fold_instances, mut fold_result, cross_opts)
	} else { // ie, asking for multiple classifiers...
		mut classifier_array := []Classifier{}
		mut instances_to_be_classified := [][][]u8{}
		mut mult_opts := cross_opts
		for i in mult_opts.classifier_indices {
			mut params := mult_opts.multiple_classifiers[i].classifier_options
			mult_opts.Parameters = params
			fold_result.Parameters = params
			part_cl := make_classifier(mut part_ds, mult_opts)
			classifier_array << part_cl
			byte_values_array = [][]u8{}
			for attr in part_cl.attribute_ordering {
				j := fold.attribute_names.index(attr)
				byte_values_array << process_fold_data(part_cl.trained_attributes[attr],
					fold.data[j])
			}
			m_fold_instances := transpose(byte_values_array)
			instances_to_be_classified << m_fold_instances
		}
		fold_result = multiple_classify_in_cross(current_fold, classifier_array, transpose(instances_to_be_classified), mut
			fold_result, mult_opts)
	}
	// println('fold_result.maximum_hamming_distance: ${fold_result.maximum_hamming_distance}')
	return fold_result
}

// process_fold_data
fn process_fold_data(part_attr TrainedAttribute, fold_data []string) []u8 {
	mut byte_vals := []u8{cap: fold_data.len}
	// for a continuous attribute
	if part_attr.attribute_type == 'C' {
		values := fold_data.map(f32(strconv.atof_quick(it)))
		byte_vals << bin_values_array(values, part_attr.minimum, part_attr.maximum, part_attr.bins)
	} else {
		byte_vals << fold_data.map(u8(part_attr.translation_table[it]))
	}
	return byte_vals
}

// option_worker
fn option_worker(work_channel chan int, result_channel chan CrossVerifyResult, pick_list []int, folds int, ds Dataset, opts Options) {
	for {
		mut current_fold := <-work_channel
		if current_fold < 0 {
			break
		}
		result_channel <- do_one_fold(pick_list, current_fold, folds, ds, opts)
	}
}

// multiple_classify_in_cross classifies each instance in an array, and
// returns the results of the classification.
fn multiple_classify_in_cross(fold int, m_cl []Classifier, m_test_instances [][][]u8, mut result CrossVerifyResult, opts Options) CrossVerifyResult {
	// println('opts in multiple_classify_in_cross: ${opts}')
	// println('labeled_classes in multiple_classify_in_cross: ${result.labeled_classes}')
	// for each instance in the test data, perform a classification
	for i, test_instance in m_test_instances {
		// println('i: $i test_instance: $test_instance')
		m_classify_result := multiple_classifier_classify(fold, m_cl, test_instance, result.labeled_classes,
			opts)
		result.inferred_classes << m_classify_result.inferred_class
		result.actual_classes << result.labeled_classes[i]
		result.nearest_neighbors_by_class << m_classify_result.nearest_neighbors_by_class
	}
	result.MultipleOptions = opts.MultipleOptions
	result.MultipleClassifiersArray = opts.MultipleClassifiersArray
	// println('result in multiple_classify_in_cross: ${result}')
	return result
}

// classify_in_cross classifies each instance in an array, and
// returns the results of the classification.
fn classify_in_cross(cl Classifier, test_instances [][]u8, mut result CrossVerifyResult, opts Options) CrossVerifyResult {
	// for each instance in the test data, perform a classification
	for i, test_instance in test_instances {
		result.inferred_classes << classify_instance(i, cl, test_instance, opts).inferred_class
		result.actual_classes << result.labeled_classes[i]
	}
	return result
}
