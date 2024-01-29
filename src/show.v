// show.v
// in order to establish style consistency, aim to use magenta underline
// for the first line of each output, and blue underline for table headings.
// use bold green for subheadings
// ie, println(m_u('\nfirst line')
// println(b_u('table header')
// println(g_b('subheading')
//
// this website https://towardsdatascience.com/multi-class-metrics-made-simple-part-ii-the-f1-score-ebe8b2c2ca1 gives the
// best explanation of multiclass metrics and how they're calculated

module vhammll

import arrays
import strings
// import math

// pad
fn pad(l int) string {
	return strings.repeat(' '[0], l)
}

fn verbose_result(i int, cl Classifier, classify_result ClassifyResult) {
	println('case: ${i:-7}    classes: ${cl.classes.join(' | ')}')
	println('inferred class                   ratio    sphere index   radius   nearest neighbours')
	println('${classify_result.inferred_class:-30}  ${get_ratio(classify_result.nearest_neighbors_by_class):6.2f}    ${classify_result.sphere_index:12}   ${classify_result.hamming_distance:6}   ${classify_result.nearest_neighbors_by_class:-17}  \n')
}

// show_analyze prints out to the console, a series of tables detailing a
// dataset. It takes as input an AnalyzeResult struct generated by
// analyze_dataset().
pub fn show_analyze(result AnalyzeResult) {
	mut show := []string{}
	show << m_u('\nAnalysis of Dataset:') + lg(' ${result.datafile_path} ') +
		m('(File Type: ${result.datafile_type})')
	if result.class_missing_purge_flag {
		show << r('Note: instances with missing class values were purged.')
	}
	show << g_b('All Attributes:')
	show << b_u(' Index  Name${' ':36}Count  Uniques  Missing      %  Type')
	mut total_count := 0
	mut total_missings := 0

	for attr in result.attributes {
		show << '${attr.id:6}  ${attr.name:-37}  ${attr.count:6}  ${attr.uniques:7}  ${attr.missing:7}  ${attr.missing * 100 / f32(attr.count):5.1f}  ${attr.att_type:4}'
		total_count += attr.count
		total_missings += attr.missing
	}

	show << [
		'______${' ':40}_______           _______  _____',
		'Totals (less Class attribute)              ${total_count:10}        ${total_missings:10}  ${total_missings * 100 / f32(total_count):5.2f}%',
	]
	show << g_b('Counts of Attributes by Type')
	show << b_u('Type        Count')
	mut types := []string{}
	for attr in result.attributes {
		types << attr.att_type
	}
	for key, value in element_counts(types) {
		show << '${key}          ${value:6}'
	}
	show << 'Total:     ${types.len:6}'
	disc_atts := result.attributes.filter(it.for_training && it.att_type == 'D')
	show << g_b('Discrete Attributes for Training') + ' (${disc_atts.len} attributes)'
	show << b_u(' Index  Name${' ':34}Uniques  Missing      %')
	for attr in disc_atts {
		show << '${attr.id:6}  ${attr.name:-37} ${attr.uniques:7}  ${attr.missing:7}  ${attr.missing * 100 / f32(attr.count):5.1f}'
	}
	cont_atts := result.attributes.filter(it.for_training && it.att_type == 'C')
	show << g_b('Continuous Attributes for Training') + ' (${cont_atts.len} attributes)'

	show << b_u(' Index  Name${' ':34}Uniques  Missing      %         Min        Max' +
		'       Mean     Median')
	for attr in cont_atts {
		show <<
			'${attr.id:6}  ${attr.name:-37} ${attr.uniques:7}  ${attr.missing:7}  ${attr.missing * 100 / f32(attr.count):5.1f}' +
			' ${attr.min:10.3g} ${attr.max:10.3g} ${attr.mean:10.3g} ${attr.median:10.3g}'
	}
	show << g_b('The Class Attribute: "${result.class_name}"') +
		' (${result.class_counts.len} classes)'
	show << b_u('Class Value           Cases')
	for key, value in result.class_counts {
		show << '${key:-20}  ${value:5}'
	}
	print_array(show)
}

// show_rank_attributes
pub fn show_rank_attributes(result RankingResult) {
	mut exclude_phrase := 'included'
	if result.exclude_flag {
		exclude_phrase = 'excluded'
	}
	println(m_u('\nAttributes Sorted by Rank Value, for "${result.path}"'))
	println('Missing values: ${exclude_phrase}')
	println('Bin range for continuous attributes: from ${result.binning.lower} to ${result.binning.upper} with interval ${result.binning.interval}')
	println(if result.weight_ranking_flag { 'Weighted' } else { 'Unweighted' } +
		' by class prevalences')
	println('Purging of instances with missing class values: ${result.class_missing_purge_flag}')
	println(b_u('         Name                         Index  Type   Rank Value   Bins'))
	mut array_to_print := []string{}
	for i, attr in result.array_of_ranked_attributes {
		array_to_print << '${i + 1:6}   ${attr.attribute_name:-27} ${attr.attribute_index:6} ${attr.attribute_type:2}         ${attr.rank_value:7.2f} ${attr.bins:6}'
	}
	print_array(array_to_print)
}

// show_classifier outputs to the console information about a classifier
pub fn show_classifier(cl Classifier) {
	println(m_u('\nClassifier from "${cl.datafile_path}"'))
	show_parameters(cl.Parameters, cl.LoadOptions)
	println(b_u('Index  Attribute                   Type  Rank Value   Uniques       Min        Max  Bins'))
	for attr, val in cl.trained_attributes {
		println('${val.index:5}  ${attr:-27} ${val.attribute_type:-4}  ${val.rank_value:10.2f}' +
			if val.attribute_type == 'C' { '          ${val.minimum:10.2f} ${val.maximum:10.2f} ${val.bins:5}' } else { '      ${val.translation_table.len:4}' })
	}
	println(g_b('\nClassifier History:'))
	println(b_u('Date & Time (UTC)    Event   From file                   Original Instances' +
		if cl.purge_flag { '  After purging' } else { '' }))
	// println(b_u('Date & Time (UTC)    Event   From file                   Original Instances  After purging',
	// 'underline'), 'blue'))
	for events in cl.history {
		println(
			'${events.event_date:-19}  ${events.event:-6}  ${events.file_path:-35} ${events.prepurge_instances_count:10}' +
			if cl.purge_flag { ' ${events.instances_count:14}' } else { '' })
	}
}

// show_parameters
fn show_parameters(p Parameters, load_options LoadOptions) {
	if p.number_of_attributes.len == 1 {
		println('Number of attributes: ' +
			if p.number_of_attributes[0] == 0 { 'all' } else { '${p.number_of_attributes[0]}' })
	}
	println('Binning range for continuous attributes: ' +
		if p.binning.lower == 0 { 'not applicable (no continuous attributes used)' } else { 'from ${p.binning.lower} to ${p.binning.upper} with interval ${p.binning.interval}' })
	println('Missing values: ' + if p.exclude_flag { 'excluded' } else { 'included' })
	println('Purging of duplicate instances: ${p.purge_flag}')
	println('Prevalence weighting for ranking attributes: ${p.weight_ranking_flag}')
	println('Prevalence weighting for nearest neighbor counts: ${p.weighting_flag}')
	println('Add instances to balance class prevalences: ${p.balance_prevalences_flag}')
	println('Purging of instances with missing class values: ${load_options.class_missing_purge_flag}')
}

// show_validate
pub fn show_validate(result ValidateResult) {
	println(m_u('\nValidation of "${result.validate_file_path}" using a classifier from "${result.datafile_path}"'))
	show_parameters(result.Parameters, result.LoadOptions)
	if result.purge_flag {
		total_count := result.prepurge_instances_counts_array[0]
		purged_count := total_count - result.classifier_instances_counts[0]
		purged_percent := 100 * f64(purged_count) / total_count
		println('Instances purged: ${purged_count} out of ${total_count} (${purged_percent:6.2f}%)')
	}
	println('Number of instances validated: ${result.inferred_classes.len}')
	println(c_u('  Index   Inferred Class    Nearest Neighbor Counts by Class (${result.classes})'))
	for i, val in result.inferred_classes {
		println('${i:7}   ${val:-14}    ${result.counts[i]}')
	}
}

// show_verify
pub fn show_verify(result CrossVerifyResult, opts Options, disp DisplaySettings) {
	println(m_u('\nVerification of "${result.testfile_path}" using ' +
		if opts.multiple_flag { 'multiple classifiers ' } else { 'a classifier ' } +
		'from "${result.datafile_path}"'))
	if opts.multiple_flag {
		println('Classifier parameters are in file "${opts.multiple_classify_options_file_path}"')
		show_multiple_classifiers_options(result, opts, disp)
	} else {
		show_parameters(result.Parameters, result.LoadOptions)
	}
	// println(result)
	if result.purge_flag {
		total_count := result.prepurge_instances_counts_array[0]
		purged_count := total_count - result.classifier_instances_counts[0]
		purged_percent := 100 * f64(purged_count) / total_count
		println('Instances purged: ${purged_count} out of ${total_count} (${purged_percent:6.2f}%)')
	}
	show_cross_or_verify_result(result, disp)
}

const headers = {
	0:  'Classifier:'
	1:  'Number of attributes:'
	2:  'Binning:'
	3:  'Exclude missing values:'
	4:  'Ranking using weighting:'
	5:  'Weighting of NN counts:'
	6:  'Balance prevalences:'
	7:  'Purge duplicate cases:'
	8:  'True counts:'
	9:  'False counts:'
	10: 'Raw accuracy:'
	11: 'Balanced accuracy:'
	12: 'Maximum Hamming Distance:'
}
// show_multiple_classifiers_options expects the multiple classifiers to be in opts, and
// the classifier indices in result
fn show_multiple_classifiers_options(result CrossVerifyResult, opts Options, disp DisplaySettings) {
	// println('result in show_multiple_classifiers_options: $result')
	// println('opts in show_multiple_classifiers_options: $opts')
	println('break_on_all_flag: ${opts.break_on_all_flag}     combined_radii_flag: ${opts.combined_radii_flag}      total_nn_counts_flag: ${opts.total_nn_counts_flag}     class_missing_purge_flag: ${opts.class_missing_purge_flag}')
	println('Multiple Classifier Parameters:')
	mut row_data := []string{len: vhammll.headers.len, init: ''}
	for i in result.classifier_indices {
		par := opts.multiple_classifiers[i]
	
	// for i, par in opts.multiple_classifiers {
	// 	// println('i: $i par: $par')
	// 	if i in result.classifier_indices {
			a := par.classifier_options
			b := par.binary_metrics
			row_data[0] += '${i:-13}'
			row_data[1] += '${a.number_of_attributes[0]:-13}'
			binning := '${a.binning.lower}, ${a.binning.upper}, ${a.binning.interval}'
			row_data[2] += '${binning:-13}'
			row_data[3] += '${a.exclude_flag:-13}'
			row_data[4] += '${a.weight_ranking_flag:-13}'
			row_data[5] += '${a.weighting_flag:-13}'
			row_data[6] += '${a.balance_prevalences_flag:-13}'
			row_data[7] += '${a.purge_flag:-13}'
			row_data[8] += '${b.t_p:-6} ${b.t_n:-6}'
			row_data[9] += '${b.f_n:-6} ${b.f_p:-6}'
			row_data[10] += '${b.raw_acc:-6.2f}%      '
			row_data[11] += '${b.bal_acc:-6.2f}%      '
			row_data[12] += '${a.maximum_hamming_distance:-13}'
		
	}
	for i, row in row_data {
		println('${vhammll.headers[i]:25}   ${row}')
	}
}

// show_crossvalidation
pub fn show_crossvalidation(result CrossVerifyResult, opts Options, disp DisplaySettings) {
	// println('result in show_crossvalidation: $result')
	println(m_u('\nCross-validation of "${result.datafile_path}"' +
		if result.multiple_classify_options_file_path != '' { ' using multiple classifiers' } else { '' }))
	println('Partitioning: ' + if result.folds == 0 { 'leave-one-out' } else { '${result.folds}-fold' + if result.repetitions > 1 { ', ${result.repetitions} repetitions' + if result.random_pick { ' with random selection of instances' } else { '' }
		 } else { ''
		 }
	 })
	if result.multiple_classify_options_file_path != '' {
		println('Classifier parameters are in file "${opts.multiple_classify_options_file_path}"')
		show_multiple_classifiers_options(result, opts, disp)
	} else {
		show_parameters(result.Parameters, result.LoadOptions)
	}
	if result.purge_flag {
		total_count_avg := arrays.sum(result.prepurge_instances_counts_array) or {} / f64(result.prepurge_instances_counts_array.len)
		purged_count_avg := total_count_avg - arrays.sum(result.classifier_instances_counts) or {} / f64(result.classifier_instances_counts.len)
		purged_percent := 100 * purged_count_avg / total_count_avg
		println('Average instances purged: ${purged_count_avg:10.1f} out of ${total_count_avg} (${purged_percent:6.2f}%)')
	}
	show_cross_or_verify_result(result, disp)
}

// show_cross_or_verify_result
fn show_cross_or_verify_result(result CrossVerifyResult, disp DisplaySettings) {
	println(g_b('Results:'))
	// mut metrics := get_metrics(result)
	if !disp.expanded_flag {
		percent := (f32(result.correct_count) * 100 / result.labeled_classes.len)
		println('correct inferences: ${result.correct_count} out of ${result.labeled_classes.len} (accuracy: raw:${percent:6.2f}% balanced:${result.balanced_accuracy:6.2f}%)')
	} else {
		show_expanded_result(result)
		print_confusion_matrix(result)
	}
}

// show_expanded_result
fn show_expanded_result(result CrossVerifyResult) {
	println(g('    Class                   Instances    True Positives    Precision    Recall    F1 Score'))
	show_multiple_classes_stats(result)
	if result.class_counts.len == 2 {
		println('A correct classification to "${result.pos_neg_classes[0]}" is a True Positive (TP);\nA correct classification to "${result.pos_neg_classes[1]}" is a True Negative (TN).')
		println("   TP    FN    TN    FP  Sens'y Spec'y    PPV    NPV  F1 Score  Accuracy: Raw  Balanced")
		println('${get_binary_stats_line(result)}')
	}
}

// get_show_bins
fn get_show_bins(bins []int) string {
	if bins == [] || 0 in bins {
		return '       '
	}
	if bins.len == 1 || bins[0] == bins[1] {
		return '${bins[0]:7}'
	}
	return '${bins[0]:2} - ${bins[1]:-2}'
}

// show_bins_for_trailer
fn show_bins_for_trailer(bins []int) string {
	if bins == [] || 0 in bins {
		return ''
	}
	if bins.len == 1 || bins[0] == bins[1] {
		return '${bins[0]}'
	}
	return '${bins[0]} - ${bins[1]}'
}

// print_confusion_matrix
fn print_confusion_matrix(result CrossVerifyResult) {
	// collect confusion matrix rows into a matrix
	mut confusion_matrix := [][]f64{}
	mut data_row := []f64{}
	for key, _ in result.confusion_matrix_map {
		data_row = []
		for _, value in result.confusion_matrix_map[key] {
			data_row << value
		}
		confusion_matrix << data_row
	}
	mut header_row := []string{}
	for key, _ in result.confusion_matrix_map {
		header_row << key
	}
	mut display_confusion_matrix := [][]string{}
	mut display_row := []string{}
	for row in confusion_matrix {
		display_row = []
		for col in row {
			display_row << '${col:10.1g}'
		}
		display_confusion_matrix << display_row
	}
	for i, class in header_row {
		display_confusion_matrix[i].prepend(class)
	}
	header_row.prepend('Predicted Classes (columns)')
	display_confusion_matrix.prepend(['Actual Classes (rows)'])
	display_confusion_matrix.prepend(header_row)

	// get the length of the longest class name
	mut l := result.classes.map(it.len)
	l << 9 // to make sure that the minimum length covers up to 5 digits
	l_max := array_max(l)
	println(b_u('Confusion Matrix' +
		if result.repetitions > 1 { ' (values averaged over ${result.repetitions} repetitions):' } else { ':' }))
	mut padded_item := ''
	for i, rows in display_confusion_matrix {
		for j, item in rows {
			match true {
				i == 0 && j == 0 { // print first item in first row, ie 'predicted classes (columns)'
					print(r('${item}  '))
				}
				i == 0 { // print column headers, ie classes
					padded_item = '${pad(l_max - item.len + 2)}' + item
					print(r('${padded_item}'))
				}
				i == 1 && j == 0 { // print 'actual classes' header
					padded_item = '${pad(6)}' + item
					print(b('${padded_item}'))
				}
				j == 0 { // print first column (class names)
					padded_item = '${pad(27 - item.len)}' + item + '  '
					print(b('${padded_item}'))
				}
				else { // print numeric values for each cell
					padded_item = '${pad(l_max - item.len + 2)}' + item
					print('${padded_item}')
				}
			}
		}
		// carriage return at end of line
		println('')
	}
}

// show_expanded_explore_result
fn show_expanded_explore_result(result CrossVerifyResult, opts Options) {
	if result.pos_neg_classes[0] != '' {
		println('${opts.number_of_attributes[0]:10} ${get_show_bins(opts.bins)}  ${get_binary_stats_line(result)}')
	} else {
		println('${opts.number_of_attributes[0]:10} ${get_show_bins(opts.bins)}')
		show_multiple_classes_stats(result)
	}
}

// show_explore_header
fn show_explore_header(results ExploreResult, settings DisplaySettings) {
	// println(results)
	mut binary := false
	if results.pos_neg_classes[0] != '' {
		binary = true
	}
	mut explore_type_string := ''
	if results.testfile_path == '' {
		explore_type_string = if results.folds == 0 { 'leave-one-out ' } else { '${results.folds}-fold ' } + 'cross-validation' + if results.repetitions > 0 { '\n (${results.repetitions} repetitions' + if results.random_pick { ', with random selection of instances)' } else { ')' }
		 } else { ''
		 }
	} else {
		explore_type_string = 'verification of "${results.testfile_path}"'
	}
	println(m_u('\nExplore ${explore_type_string} using classifiers from "${results.path}"'))
	show_parameters(results.Parameters, results.LoadOptions)
	println('Over attribute range from ${results.start} to ${results.end} by interval ${results.att_interval}')
	if !settings.expanded_flag {
		println(b_u('Attributes     Bins' +
			if results.purge_flag { '       Purged instances     (%)' } else { '' } +
			'  Matches  Nonmatches  Accuracy: Raw  Balanced'))
	} else {
		if binary {
			println('A correct classification to "${results.pos_neg_classes[0]}" is a True Positive (TP);\nA correct classification to "${results.pos_neg_classes[1]}" is a True Negative (TN).')
			println(b_u('Attributes    Bins' +
				if results.purge_flag { '        Purged instances     (%)' } else { '' } +
				"     TP    FN    TN    FP  Sens'y Spec'y    PPV    NPV  F1 Score  Accuracy: Raw  Balanced"))
		} else {
			println(b_u('Attributes    Bins' +
				if results.purge_flag { '        Purged instances     (%)' } else { '' }))
			println(b_u('    Class                   Instances    True Positives    Precision    Recall    F1 Score'))
		}
	}
}

fn explore_analytics2(expr ExploreResult) map[string]Analytics {
	mut m := map[string]Analytics{}
	m['raw accuracy'] = Analytics{
		valeur: expr.array_of_results.map(it.raw_acc)[idx_max(expr.array_of_results.map(it.raw_acc))]
		idx: idx_max(expr.array_of_results.map(it.raw_acc))
	}
	m['balanced accuracy'] = Analytics{
		idx: idx_max(expr.array_of_results.map(it.balanced_accuracy))
		valeur: expr.array_of_results.map(it.balanced_accuracy)[idx_max(expr.array_of_results.map(it.balanced_accuracy))]
	}
	m['true positives'] = Analytics{
		idx: idx_max(expr.array_of_results.map(it.t_p))
		valeur: expr.array_of_results.map(it.t_p)[idx_max(expr.array_of_results.map(it.t_p))]
	}
	m['true negatives'] = Analytics{
		idx: idx_max(expr.array_of_results.map(it.t_n))
		valeur: expr.array_of_results.map(it.t_n)[idx_max(expr.array_of_results.map(it.t_n))]
	}
	for _, mut s in m {
		cvr := expr.array_of_results[s.idx]
		s.settings = analytics_settings(cvr)
		s.binary_counts = [cvr.t_p, cvr.f_n, cvr.t_n, cvr.f_p]
	}
	return m
}

// analytics_settings
fn analytics_settings(cvr CrossVerifyResult) MaxSettings {
	_, _, purged_percent := get_purged_percent(cvr)
	return MaxSettings{
		attributes_used: cvr.attributes_used
		binning: cvr.bin_values
		purged_percent: purged_percent
	}
}

// show_explore_trailer
fn show_explore_trailer(results ExploreResult, opts Options) {
	println('Command line arguments: ${opts.args}')
	println('Maximum accuracies obtained:')
	for label, a in explore_analytics2(results) {
		print('${label:28}: ')
		print(match a.valeur {
			f64 { '${a.valeur:6.2f}%' }
			int { '${a.valeur:7}' }
		})
		print(' ${a.binary_counts}')
		print(' using ${a.settings.attributes_used} attributes')
		if show_bins_for_trailer(a.settings.binning) != '' {
			print(', with binning ${show_bins_for_trailer(a.settings.binning)}')
		}
		if a.settings.purged_percent > 0.0 {
			print(', ${a.settings.purged_percent:5.2f}% instances purged.')
		}
		println('')
	}
	println('')
}

// get_purged_percent
fn get_purged_percent(result CrossVerifyResult) (f64, f64, f64) {
	total_count_avg := arrays.sum(result.prepurge_instances_counts_array) or {} / f64(result.prepurge_instances_counts_array.len)
	purged_count_avg := total_count_avg - arrays.sum(result.classifier_instances_counts) or {} / f64(result.classifier_instances_counts.len)
	return purged_count_avg, total_count_avg, 100 * purged_count_avg / total_count_avg
}

// show_explore_line displays on the console the results of each
// cross-validation or verification during an explore session.
fn show_explore_line(result CrossVerifyResult, settings DisplaySettings) {
	// println(result)
	// do nothing if neither the -s or the -e flag was set
	if settings.show_flag || settings.expanded_flag {
		purged, total, purged_percent := get_purged_percent(result)
		if !settings.expanded_flag {
			accuracy_percent := (f32(result.correct_count) * 100 / result.labeled_classes.len)
			println('${result.attributes_used:10}  ${get_show_bins(result.bin_values)}' +
				if result.purge_flag {
				'${purged:10.1f} out of ${total} (${purged_percent:5.2f})'
			} else {
				''
			} +
				'  ${result.correct_count:7}  ${result.labeled_classes.len - result.correct_count:10}       ${accuracy_percent:7.2f}%  ${result.balanced_accuracy:7.2f}%')
		} else {
			if result.pos_neg_classes[0] != '' {
				println('${result.attributes_used:10} ${get_show_bins(result.bin_values)}' + if result.purge_flag {
					' ${purged:10.1f} out of ${total} (${purged_percent:5.2f})'
				} else {
					''
				} + '  ${get_binary_stats_line(result)}')
			} else {
				println('${result.attributes_used:10} ${get_show_bins(result.bin_values)}' + if result.purge_flag {
					' ${purged:10.1f} out of ${total} (${purged_percent:5.2f})'
				} else {
					''
				})
				show_multiple_classes_stats(result)
			}
		}
	}
}

// get_binary_stats_line
fn get_binary_stats_line(r CrossVerifyResult) string {
	return '${r.t_p:5} ${r.f_n:5} ${r.t_n:5} ${r.f_p:5}   ${r.sens:5.3f}  ${r.spec:5.3f}  ${r.ppv:5.3f}  ${r.npv:5.3f}     ${r.f1_score_binary:5.3f}        ${r.raw_acc:6.2f}%   ${r.balanced_accuracy:6.2f}%'
}

// show_multiple_classes_stats
fn show_multiple_classes_stats(result CrossVerifyResult) {
	mut show_result := []string{}
	m := result.Metrics
	for i, class in result.classes {
		show_result << '    ${class:-21}       ${result.labeled_instances[class]:5}   ${result.correct_inferences[class]:5} (${f32(result.correct_inferences[class]) * 100 / result.labeled_instances[class]:6.2f}%)        ${m.precision[i]:5.3f}     ${m.recall[i]:5.3f}       ${m.f1_score[i]:5.3f}'
	}
	show_result << '        Totals                  ${result.total_count:5}   ${result.correct_count:5} (accuracy: raw:${result.raw_acc:6.2f}% balanced:${result.balanced_accuracy:6.2f}%)'
	for i, avg_type in m.avg_type {
		show_result << '${avg_type.title():18} Averages:                                   ${m.avg_precision[i]:5.3f}     ${m.avg_recall[i]:5.3f}       ${m.avg_f1_score[i]:5.3f}'
	}
	print_array(show_result)
}

// show_detailed_result
fn show_detailed_result(final_inferred_class string, labeled_classes []string, mcr MultipleClassifierResults) {
	println('classifier  sphere index  radius  nearest neighbors  ratio  inferred class')
	for i, icr in mcr.results_by_classifier {
		a := icr.results_by_radius.last()
		println('${mcr.classifier_indices[i]:10}  ${a.sphere_index:12}  ${a.radius:6}  ${a.nearest_neighbors_by_class:-17} ${get_ratio(a.nearest_neighbors_by_class):6.2f}  ${a.inferred_class} ')
	}
	println('           ${final_inferred_class} ${labeled_classes}')
}

// get_ratio
fn get_ratio(a []int) f64 {
	// println('a in get_ratio: ${a}')
	if a.all(it == 0) {
		return 1
	}
	if 0 in a {
		return f64(array_max(a.filter(it != 0)))
	}
	return f64(array_max(a)) / array_min(a)
}
