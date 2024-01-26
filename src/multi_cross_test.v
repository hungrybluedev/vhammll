// multi_cross_test.v

module vhammll

import os
// import vtl

fn testsuite_begin() ? {
	if os.is_dir('tempfolder_multi_cross') {
		os.rmdir_all('tempfolder_multi_cross')!
	}
	os.mkdir_all('tempfolder_multi_cross')!
}

fn testsuite_end() ? {
	os.rmdir_all('tempfolder_multi_cross')!
}

fn test_multiple_crossvalidate() ? {
	mut disp := DisplaySettings{
		verbose_flag: false
		expanded_flag: true
	}
	mut opts := Options{
		// folds: 3
		break_on_all_flag: true
		combined_radii_flag: false
		weighting_flag: false
		// total_nn_counts_flag: true
		command: 'explore'
		concurrency_flag: true
	}
	mut result := CrossVerifyResult{}
	// create an .opts file with settings for multiple classifiers
	opts.datafile_path = 'datasets/2_class_developer.tab'
	opts.settingsfile_path = 'tempfolder_multi_cross/2_class.opts'
	opts.append_settings_flag = true
	opts.weight_ranking_flag = true
	mut ds := load_file(opts.datafile_path)
	mut er := explore(ds, opts)
	// do an ordinary crossvalidation
	opts.command = 'cross'
	opts.number_of_attributes = [3]
	opts.bins = [1, 3]
	result = cross_validate(ds, opts)

	// now do a multiple classifier crossvalidation
	opts.multiple_flag = true
	opts.multiple_classify_options_file_path = opts.settingsfile_path
	opts.classifier_indices = [2]
	assert cross_validate(ds, opts, disp).confusion_matrix_map == {
		'm': {
			'm': 8.0
			'f': 1.0
		}
		'f': {
			'm': 1.0
			'f': 3.0
		}
	}
	opts.classifier_indices = [3]
	// assert cross_validate(ds, opts, disp).confusion_matrix_map == result.confusion_matrix_map
	opts.classifier_indices = [2, 3]
	assert cross_validate(ds, opts, disp).confusion_matrix_map == {
		'm': {
			'm': 8.0
			'f': 1.0
		}
		'f': {
			'm': 1.0
			'f': 3.0
		}
	}
}

fn test_multiple_crossvalidate_mixed_attributes() ? {
	mut opts := Options{
		datafile_path: 'datasets/2_class_developer.tab'
		settingsfile_path: 'tempfolder_multi_cross/2_class_big.opts'
		append_settings_flag: true
		command: 'explore'
		concurrency_flag: true
	}

	mut disp := DisplaySettings{
		expanded_flag: false 
		verbose_flag: false
		show_flag: true
	}
	// opts.number_of_attributes = [11,13]
	// opts.bins = [1,10]
	mut ds := load_file(opts.datafile_path)
	ft := [false, true]
	for pf in ft {
		opts.uniform_bins = pf
		for wr in [false, true] {
			opts.weight_ranking_flag = wr
			for w in [false, true] {
				opts.weighting_flag = w
				er := explore(ds, opts, disp)
			}
		}
	}
	display_file(opts.settingsfile_path, opts)
	opts.append_settings_flag = false
	opts.command = 'cross'
	opts.classifier_indices = [3, 4, 6, 14]
	opts.multiple_classify_options_file_path = opts.settingsfile_path
	opts.multiple_flag = true
	// for ci in [[3],[4],[6],[14],[3,4],[3,6],[4,6],[3,4,6],[3,4,6,14]] {
	for ci in [[3, 11, 4, 5, 6, 14]] {
		opts.classifier_indices = ci
		for ma in ft {
			opts.break_on_all_flag = ma
			for mc in ft {
				opts.combined_radii_flag = mc
				for t in ft {
					opts.total_nn_counts_flag = t
				}
				cross_validate(ds, opts, disp)
			}
		}
	}
}

// fn test_multiple_crossvalidate_only_discrete_attributes() ? {
// 	mut opts := Options{
// 		datafile_path: 'datasets/breast-cancer-wisconsin-disc.tab'
// 		settingsfile_path: 'tempfolder_multi_cross/breast-cancer-wisconsin-disc.opts'
// 		append_settings_flag: true
// 		command: 'explore'
// 		concurrency_flag: true
// 	}

// 	mut disp := DisplaySettings{
// 		expanded_flag: true 
// 		verbose_flag: false
// 	}

// 	mut ds := load_file(opts.datafile_path)
// 	ft := [false, true]
// 	for pf in ft {
// 		opts.purge_flag = pf
// 		for wr in [false, true] {
// 			opts.weight_ranking_flag = wr
// 			for w in [false, true] {
// 				opts.weighting_flag = w
// 				er := explore(ds, opts, disp)
// 			}
// 		}
// 	}
// 	display_file(opts.settingsfile_path, opts)
// 	opts.append_settings_flag = false
// 	opts.command = 'cross'
// 	opts.classifier_indices = [3, 4, 6, 14]
// 	opts.multiple_classify_options_file_path = opts.settingsfile_path
// 	opts.multiple_flag = true
// 	// for ci in [[3],[4],[6],[14],[3,4],[3,6],[4,6],[3,4,6],[3,4,6,14]] {
// 	opts.classifier_indices = [6,14,3,11,23,31]

// 		for ma in ft {
// 			opts.break_on_all_flag = ma
// 			for mc in ft {
// 				opts.combined_radii_flag = mc
// 				for t in ft {
// 					opts.total_nn_counts_flag = t
// 				}
// 				cross_validate(ds, opts, disp)
// 			}
// 		}
	
// 	opts.command = 'cross'
// 	ds = load_file(opts.datafile_path)
// 	opts.number_of_attributes = [7]
// 	mut result := cross_validate(ds, opts, disp)
// 	opts.multiple_flag = true
// 	opts.multiple_classify_options_file_path = opts.settingsfile_path
// 	opts.classifier_indices = [2]
// 	assert cross_validate(ds, opts, disp).confusion_matrix_map == {
// 		'benign':    {
// 			'benign':    445.0
// 			'malignant': 13.0
// 		}
// 		'malignant': {
// 			'benign':    16.0
// 			'malignant': 225.0
// 		}
// 	}
// 	opts.classifier_indices = [3]
// 	assert cross_validate(ds, opts, disp).confusion_matrix_map == {
// 		'benign':    {
// 			'benign':    447.0
// 			'malignant': 11.0
// 		}
// 		'malignant': {
// 			'benign':    24.0
// 			'malignant': 217.0
// 		}
// 	}
// 	opts.classifier_indices = [2, 3]
// 	assert cross_validate(ds, opts, disp).confusion_matrix_map == {
// 		'benign':    {
// 			'benign':    446.0
// 			'malignant': 12.0
// 		}
// 		'malignant': {
// 			'benign':    22.0
// 			'malignant': 219.0
// 		}
// 	}
// }

// fn test_multiple_crossvalidate_mixed_attributes() ? {
// 	mut opts := Options{
// 		datafile_path: 'datasets/anneal.tab'
// 		settingsfile_path: 'tempfolder_multi_cross/anneal.opts'
// 		append_settings_flag: true
// 		command: 'explore'
// 		concurrency_flag: true
// 	}

// 	mut disp := DisplaySettings{
// 		expanded_flag: false 
// 		verbose_flag: false
// 		show_flag: true
// 	}
// 	opts.number_of_attributes = [11,13]
// 	opts.bins = [1,10]
// 	mut ds := load_file(opts.datafile_path)
// 	ft := [false, true]
// 	for pf in ft {
// 		opts.uniform_bins = pf
// 		for wr in [false, true] {
// 			opts.weight_ranking_flag = wr
// 			for w in [false, true] {
// 				opts.weighting_flag = w
// 				er := explore(ds, opts, disp)
// 			}
// 		}
// 	}
// 	display_file(opts.settingsfile_path, opts)
// 	opts.append_settings_flag = false
// 	opts.command = 'cross'
// 	opts.classifier_indices = [3, 4, 6, 14]
// 	opts.multiple_classify_options_file_path = opts.settingsfile_path
// 	opts.multiple_flag = true
// 	// for ci in [[3],[4],[6],[14],[3,4],[3,6],[4,6],[3,4,6],[3,4,6,14]] {
// 	for ci in [[3, 11, 4, 5, 6, 14]] {
// 		opts.classifier_indices = ci
// 		for ma in ft {
// 			opts.break_on_all_flag = ma
// 			for mc in ft {
// 				opts.combined_radii_flag = mc
// 				for t in ft {
// 					opts.total_nn_counts_flag = t
// 				}
// 				cross_validate(ds, opts, disp)
// 			}
// 		}
// 	}
// 	opts.command = 'cross'
// 	ds = load_file(opts.datafile_path)
// 	opts.number_of_attributes = [7]
// 	mut result := cross_validate(ds, opts, disp)
// 	opts.multiple_flag = true
// 	opts.multiple_classify_options_file_path = opts.settingsfile_path
// 	opts.classifier_indices = [2]
// 	assert cross_validate(ds, opts, disp).confusion_matrix_map == {
// 		'benign':    {
// 			'benign':    445.0
// 			'malignant': 13.0
// 		}
// 		'malignant': {
// 			'benign':    16.0
// 			'malignant': 225.0
// 		}
// 	}
// 	opts.classifier_indices = [3]
// 	assert cross_validate(ds, opts, disp).confusion_matrix_map == {
// 		'benign':    {
// 			'benign':    447.0
// 			'malignant': 11.0
// 		}
// 		'malignant': {
// 			'benign':    24.0
// 			'malignant': 217.0
// 		}
// 	}
// 	opts.classifier_indices = [2, 3]
// 	assert cross_validate(ds, opts, disp).confusion_matrix_map == {
// 		'benign':    {
// 			'benign':    446.0
// 			'malignant': 12.0
// 		}
// 		'malignant': {
// 			'benign':    22.0
// 			'malignant': 219.0
// 		}
// 	}
// }
