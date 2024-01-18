// totalnn_test.v

// test_multiple_classifiers using the totalnn algorithm

module vhammll

import os
// import vtl

fn testsuite_begin() ? {
	if os.is_dir('tempfolder_totalnn') {
		os.rmdir_all('tempfolder_totalnn')!
	}
	os.mkdir_all('tempfolder_totalnn')!
}

fn testsuite_end() ? {
	os.rmdir_all('tempfolder_totalnn')!
}

// fn test_multiple_classifier_classify_totalnn() {
// 	mut opts := Options{
// 		break_on_all_flag: true
// 		combined_radii_flag: false
// 		weighting_flag: false
// 		show_flag: false
// 		total_nn_counts_flag: true
// 		command: 'explore'
// 	}
// 	mut result := CrossVerifyResult{}

// 	opts.datafile_path = 'datasets/2_class_developer.tab'
// 	opts.settingsfile_path = 'tempfolder_totalnn/2_class.opts'
// 	opts.append_settings_flag = true
// 	opts.weight_ranking_flag = true
// 	mut ds := load_file(opts.datafile_path)
// 	mut er := explore(ds, opts)
// 	opts.command = 'cross'
// 	disp.verbose_flag = false
// 	disp.expanded_flag = false
// 	opts.number_of_attributes = [3]
// 	opts.bins = [1, 3]
// 	result = cross_validate(ds, opts)
// 	opts.multiple_flag = true
// 	opts.multiple_classify_options_file_path = opts.settingsfile_path
// 	opts.classifier_indices = [2]
// 	// assert cross_validate(ds, opts).confusion_matrix_map == {
// 	// 	'm': {
// 	// 		'm': 8.0
// 	// 		'f': 1.0
// 	// 	}
// 	// 	'f': {
// 	// 		'm': 1.0
// 	// 		'f': 3.0
// 	// 	}
// 	// }
// 	opts.classifier_indices = [3]
// 	assert cross_validate(ds, opts).confusion_matrix_map == result.confusion_matrix_map
// 	opts.classifier_indices = [2, 3]
// 	// assert cross_validate(ds, opts).confusion_matrix_map == {
// 	// 	'm': {
// 	// 		'm': 8.0
// 	// 		'f': 1.0
// 	// 	}
// 	// 	'f': {
// 	// 		'm': 1.0
// 	// 		'f': 3.0
// 	// 	}
// 	// }
// }

fn test_multiple_verify() ? {
	mut opts := Options{
		concurrency_flag: false
		break_on_all_flag: true
		total_nn_counts_flag: true
		command: 'verify'
	}
	mut result := CrossVerifyResult{}
	opts.datafile_path = 'datasets/leukemia38train.tab'
	opts.testfile_path = 'datasets/leukemia34test.tab'
	opts.settingsfile_path = 'tempfolder_totalnn/leuk.opts'
	opts.append_settings_flag = true
	opts.number_of_attributes = [1]
	opts.bins = [5, 5]
	opts.purge_flag = true
	opts.weight_ranking_flag = true
	// check that the non-multiple verify works OK, and that the
	// settings file is getting appended
	mut ds := load_file(opts.datafile_path)
	// mut cl := make_classifier(ds, opts)
	result0 := verify(opts, expanded_flag: true)
	println('result0 in test_multiple_verify: ${result0}')
	assert result0.confusion_matrix_map == {
		'ALL': {
			'ALL': 17.0
			'AML': 3.0
		}
		'AML': {
			'ALL': 0.0
			'AML': 14.0
		}
	}
	opts.bins = [2, 2]
	opts.purge_flag = false
	result1 := verify(opts, expanded_flag: false)
	assert result1.confusion_matrix_map == {
		'ALL': {
			'ALL': 19.0
			'AML': 1.0
		}
		'AML': {
			'ALL': 9.0
			'AML': 5.0
		}
	}
	// verify that the settings file was correctly saved, and
	// is the right length
	assert os.file_size(opts.settingsfile_path) == 1042

	// test verify with multiple_classify_options_file_path
	opts.multiple_flag = true
	opts.multiple_classify_options_file_path = opts.settingsfile_path
	opts.classifier_indices = [0]
	result = verify(opts, expanded_flag: true)
	println('result with classifier 0 in test_multiple_verify: ${result}')
	// with classifier 0
	// assert result.confusion_matrix_map == result0.confusion_matrix_map

	// opts.classifier_indices = [1]
	// result = verify(cl, opts, expanded_flag: true)
	// // with classifier 1
	// // assert result.confusion_matrix_map == result1.confusion_matrix_map
	// // with both classifiers
	// opts.classifier_indices = []
	// result = verify(cl, opts, verbose_flag: false, expanded_flag: true)

	// assert result.confusion_matrix_map == {
	// 	'ALL': {
	// 		'ALL': 17.0
	// 		'AML': 3.0
	// 	}
	// 	'AML': {
	// 		'ALL': 6.0
	// 		'AML': 8.0
	// 	}
	// }
}

// fn test_multiple_crossvalidate() ? {
// 	mut opts := Options{
// 		break_on_all_flag: true
// 		combined_radii_flag: false
// 		weighting_flag: false
// 		show_flag: false
// 		total_nn_counts_flag: true
// 		command: 'explore'
// 	}
// 	mut result := CrossVerifyResult{}

// 	opts.datafile_path = 'datasets/2_class_developer.tab'
// 	opts.settingsfile_path = 'tempfolder_totalnn/2_class.opts'
// 	opts.append_settings_flag = true
// 	opts.weight_ranking_flag = true
// 	mut er := explore(load_file(opts.datafile_path), opts)
// 	opts.command = 'cross'
// 	mut ds := load_file(opts.datafile_path)
// 	opts.number_of_attributes = [3]
// 	opts.bins = [1, 3]
// 	result = cross_validate(ds, opts)
// 	opts.multiple_flag = true
// 	opts.multiple_classify_options_file_path = opts.settingsfile_path
// 	opts.classifier_indices = [2]
// 	assert cross_validate(ds, opts).confusion_matrix_map == {
// 		'm': {
// 			'm': 8.0
// 			'f': 1.0
// 		}
// 		'f': {
// 			'm': 1.0
// 			'f': 3.0
// 		}
// 	}
// 	opts.classifier_indices = [3]
// 	assert cross_validate(ds, opts).confusion_matrix_map == result.confusion_matrix_map
// 	opts.classifier_indices = [2, 3]
// 	assert cross_validate(ds, opts).confusion_matrix_map == {
// 		'm': {
// 			'm': 8.0
// 			'f': 1.0
// 		}
// 		'f': {
// 			'm': 1.0
// 			'f': 3.0
// 		}
// 	}
// }

// // test_multiple_crossvalidate_only_discrete_attributes
// fn test_multiple_crossvalidate_only_discrete_attributes() ? {
// 	mut opts := Options{
// 		datafile_path: 'datasets/breast-cancer-wisconsin-disc.tab'
// 		settingsfile_path: 'tempfolder_totalnn/breast-cancer-wisconsin-disc.opts'
// 		append_settings_flag: true
// 		total_nn_counts_flag: true
// 		command: 'explore'
// 	}

// 	ds := load_file(opts.datafile_path)
// 	ft := [false, true]
// 	for pf in ft {
// 		opts.purge_flag = pf
// 		for wr in [false, true] {
// 			opts.weight_ranking_flag = wr
// 			for w in [false, true] {
// 				opts.weighting_flag = w
// 				er := explore(ds, opts)
// 			}
// 		}
// 	}
// 	display_file(opts.settingsfile_path, opts)
// opts.append_settings_flag = false
// opts.command = 'cross'
// opts.classifier_indices = [3, 4, 6, 14]
// opts.multiple_classify_options_file_path = opts.settingsfile_path
// opts.multiple_flag = true
// // for ci in [[3],[4],[6],[14],[3,4],[3,6],[4,6],[3,4,6],[3,4,6,14]] {
// for ci in [[3,11,4,5,6,14]] {
// 	opts.classifier_indices = ci
// 	for ma in ft {
// 		opts.break_on_all_flag = ma
// 		for mc in ft {
// 			opts.combined_radii_flag = mc
// 			cross_validate(ds, opts)
// 		}
// 	}
// }
// opts.command = 'cross'
// ds = load_file(opts.datafile_path)
// opts.number_of_attributes = [7]
// result = cross_validate(ds, opts)
// opts.multiple_flag = true
// opts.multiple_classify_options_file_path = opts.settingsfile_path
// opts.classifier_indices = [2]
// assert cross_validate(ds, opts).confusion_matrix_map == {
// 	'm': {
// 		'm': 8.0
// 		'f': 1.0
// 	}
// 	'f': {
// 		'm': 1.0
// 		'f': 3.0
// 	}
// }
// opts.classifier_indices = [3]
// assert cross_validate(ds, opts).confusion_matrix_map == result.confusion_matrix_map
// opts.classifier_indices = [2, 3]
// assert cross_validate(ds, opts).confusion_matrix_map == {
// 	'm': {
// 		'm': 9.0
// 		'f': 0.0
// 	}
// 	'f': {
// 		'm': 1.0
// 		'f': 3.0
// 	}
// }
// }

// // test verify with a non-saved classifier
// opts.command = 'make'
// opts.datafile_path = 'datasets/multiples-train.tab'
// opts.testfile_path = 'datasets/multiples-verify.tab'
// opts.classifierfile_path = ''
// opts.bins = [1,2]
// opts.number_of_attributes = [2]
// opts.weighting_flag = false
// ds = load_file(opts.datafile_path)
// // println(ds.class_values)
// cl1 = make_classifier(mut ds, opts)
// mut test_ds1 := load_file(opts.testfile_path)
// // println(test_ds1.class_values)
// mut test_instances1 := generate_test_instances_array(cl1, test_ds1)
// // opts.command = 'verify'
// // vr1 = verify(cl1, opts)?
// // println(vr1)
// opts.bins = [1,1]
// opts.number_of_attributes = [1]
// opts.weighting_flag = true
// cl2 = make_classifier(mut ds, opts)

// mut test_ds2 := load_file(opts.testfile_path)
// mut test_instances2 := generate_test_instances_array(cl2, test_ds1)
// // println('test_instances1: $test_instances1')
// // println('test_instances2: $test_instances2')
// for i in 0..test_instances1.len {
// // println(multiple_classifier_classify(i, [cl1, cl2], [test_instances1[i], test_instances2[i]], opts).inferred_class)
// }
// println('Done with multiples-train.tab')

// opts.datafile_path = 'datasets/bcw350train'
// opts.testfile_path = 'datasets/bcw174test'
// opts.classifierfile_path = ''
// opts.number_of_attributes = [1]
// opts.weighting_flag = true
// ds = load_file(opts.datafile_path)
// cl1 = make_classifier(mut ds, opts)
// test_ds1 = load_file(opts.testfile_path)
// // println(test_ds1.class_values)
// test_instances1 = generate_test_instances_array(cl1, test_ds1)
// opts.number_of_attributes = [6]
// opts.weighting_flag = true
// cl2 = make_classifier(mut ds, opts)
// test_ds2 = load_file(opts.testfile_path)
// // println(test_ds2)
// test_instances2 = generate_test_instances_array(cl2, test_ds1)
// // println('test_instances1: $test_instances1')
// // println('test_instances2: $test_instances2')
// mut correct_count := 0
// mut incorrect_count := 0
// mut raw_accuracy := 0.0
// for i in 0..test_instances1.len {
// 	mc_result = multiple_classifier_classify(i, [cl1, cl2], [test_instances1[i], test_instances2[i]], opts)
// 	if test_ds2.class_values[i] == mc_result.inferred_class {

// 		correct_count += 1
// 	} else {
// 	 	println('i: $i  actual class: ${test_ds2.class_values[i]} inferred_class: $mc_result.inferred_class')
// 	 	incorrect_count += 1
// 	 }
// }
// println('correct_count: $correct_count incorrect_count: $incorrect_count')

// println('Done with bcw350train')

// opts.datafile_path = 'datasets/leukemia38train.tab'
// opts.testfile_path = 'datasets/leukemia34test.tab'
// opts.classifierfile_path = ''
// opts.number_of_attributes = [1]
// opts.bins = [5,5]
// opts.weighting_flag = true
// ds = load_file(opts.datafile_path)
// cl1 = make_classifier(mut ds, opts)
// test_ds1 = load_file(opts.testfile_path)
// // println(test_ds1.class_values)
// test_instances1 = generate_test_instances_array(cl1, test_ds1)
// opts.number_of_attributes = [10]
// opts.bins = [1,3]
// opts.weighting_flag = false
// cl2 = make_classifier(mut ds, opts)
// test_ds2 = load_file(opts.testfile_path)
// // println(test_ds2)
// test_instances2 = generate_test_instances_array(cl2, test_ds1)
// // println('test_instances1: $test_instances1')
// // println('test_instances2: $test_instances2')
// correct_count = 0
// incorrect_count = 0
// raw_accuracy = 0.0
// for i in 0..test_instances1.len {
// 	mc_result = multiple_classifier_classify(i, [cl1, cl2], [test_instances1[i], test_instances2[i]], opts)
// 	if test_ds2.class_values[i] == mc_result.inferred_class {

// 		correct_count += 1
// 	} else {
// 	 	println('i: $i  actual class: ${test_ds2.class_values[i]} inferred_class: $mc_result.inferred_class')
// 	 	incorrect_count += 1
// 	 }
// }
// println('correct_count: $correct_count incorrect_count: $incorrect_count')

// println('Done with leukemia')

// // now with a saved classifier
// opts.outputfile_path = 'tempfolder_totalnn/classifierfile'
// cl = Classifier{}
// result = CrossVerifyResult{}
// cl = make_classifier(mut ds, opts)
// cl = Classifier{}
// result = verify(load_classifier_file('tempfolder_totalnn/classifierfile')?, opts)?
// assert result.correct_count == 171
// assert result.wrong_count == 3

// println('Done with bcw350train using saved classifier')

// opts.datafile_path = 'datasets/soybean-large-train.tab'
// opts.testfile_path = 'datasets/soybean-large-test.tab'
// opts.classifierfile_path = ''
// opts.number_of_attributes = [33]
// opts.bins = [2, 16]
// opts.weighting_flag = true
// ds = load_file(opts.datafile_path)
// cl = make_classifier(mut ds, opts)
// result = verify(cl, opts)?
// assert result.correct_count == 340
// assert result.wrong_count == 36

// println('Done with soybean-large-train.tab')

// // now with a saved classifier
// opts.outputfile_path = 'tempfolder_totalnn/classifierfile'
// cl = Classifier{}
// result = CrossVerifyResult{}
// cl = make_classifier(mut ds, opts)
// cl = Classifier{}
// result = verify(load_classifier_file('tempfolder_totalnn/classifierfile')?, opts)?
// assert result.correct_count == 340
// assert result.wrong_count == 36

// println('Done with soybean-large-train.tab using saved classifier')

// if get_environment().arch_details[0] != '4 cpus' {
// 	opts.datafile_path = 'datasets/mnist_test.tab'
// 	opts.testfile_path = 'datasets/mnist_test.tab'
// 	opts.classifierfile_path = ''
// 	opts.outputfile_path = ''
// 	opts.number_of_attributes = [50]
// 	opts.bins = [2, 2]
// 	opts.weighting_flag = false
// 	disp.show_flag = false
// 	ds = load_file(opts.datafile_path)
// 	cl = make_classifier(mut ds, opts)
// 	result = verify(cl, opts)?
// 	assert result.correct_count == 9982
// 	assert result.wrong_count == 18

// 	println('Done with mnist_test.tab')

// 	// now with a saved classifier
// 	opts.outputfile_path = 'tempfolder_totalnn/classifierfile'
// 	cl = Classifier{}
// 	result = CrossVerifyResult{}
// 	cl = make_classifier(mut ds, opts)
// 	cl = Classifier{}
// 	result = verify(load_classifier_file('tempfolder_totalnn/classifierfile')?, opts)?
// 	assert result.correct_count == 9982
// 	assert result.wrong_count == 18

// 	println('Done with mnist_test.tab using saved classifier')
// }

// if get_environment().arch_details[0] != '4 cpus' {

// 	cl = Classifier{}
// 	ds = Dataset{}
// 	result = CrossVerifyResult{}
// 	opts.datafile_path = '../../mnist_train.tab'
// 	opts.testfile_path = ''
// 	opts.outputfile_path = 'tempfolder_totalnn/classifierfile'
// 	opts.number_of_attributes = [313]
// 	opts.bins = [2, 2]
// 	opts.concurrency_flag = true
// 	opts.weighting_flag = false
// 	ds = load_file(opts.datafile_path)
// 	cl = make_classifier(mut ds, opts)
// 	opts.testfile_path = 'datasets/mnist_test.tab'
// 	result = verify(load_classifier_file('tempfolder_totalnn/classifierfile') ?, opts)
// 	assert result.correct_count == 9566
// 	assert result.wrong_count == 434

// 	opts.weighting_flag = true
// 	cl = make_classifier(mut ds, opts)
// 	result = verify(cl, opts)
// 	assert result.correct_count == 9279
// 	assert result.wrong_count == 721
// }

// fn test_multiple_classifiers() {
// 	// for a two-class (binary classification)
// 	mut opts := Options{
// 		bins: [1,3]
// 		exclude_flag: false
// 		verbose_flag: false
// 		command: 'classify'
// 		number_of_attributes: [3]
// 		show_flag: false
// 		weighting_flag: false
// 		multiple_flag: true
// 	}
// 	mut ds := load_file('datasets/2_class_developer.tab')
// 	println(ds)
// 	mut cl1 := make_classifier(mut ds, opts)
// 	println(cl1)
// 	for i, instance in cl1.instances {
// 		println('$i $instance')
// 		println(classify_case(i, cl1, instance, opts).inferred_class)
// 		println('actual class: ${cl1.class_values[i]}')
// 	}

// 	assert classify_case(0, cl1, cl1.instances[0], opts).inferred_class == 'm'
// 	assert classify_case(0, cl1, cl1.instances[0], opts).nearest_neighbors_by_class == [
// 		1,
// 		0
// 	]
// 	opts.weighting_flag = true
// 	opts.bins = [1,7]
// 	opts.number_of_attributes = [1]
// 	mut cl2 := make_classifier(mut ds, opts)
// 	assert classify_case(0, cl2, cl2.instances[3], opts).inferred_class == 'f'
// 	assert classify_case(0, cl2, cl2.instances[3], opts).nearest_neighbors_by_class == [
// 		0,
// 9
// 	]
// }
