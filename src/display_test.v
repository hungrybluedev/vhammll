// display_test.v

module vhammll

import os

fn testsuite_begin() ! {
	if os.is_dir('tempfolder_display') {
		os.rmdir_all('tempfolder_display')!
	}
	os.mkdir_all('tempfolder_display')!
}

fn testsuite_end() ! {
	os.rmdir_all('tempfolder_display')!
}

fn test_display_multiple_options() ? {
	mut settings1 := ClassifierSettings{
		Parameters: Parameters{
			binning: Binning{
				lower: 1
				upper: 2
				interval: 1
			}
			number_of_attributes: [1]
			weighting_flag: true
		}
	}
	mut settings2 := ClassifierSettings{
		Parameters: Parameters{
			binning: Binning{
				lower: 1
				upper: 2
				interval: 1
			}
			number_of_attributes: [6]
			weighting_flag: true
		}
	}
	append_json_file(settings1, 'tempfolder_display/bcw.opts')
	assert os.file_size('tempfolder_display/bcw.opts') >= 416
	append_json_file(settings2, 'tempfolder_display/bcw.opts')
	assert os.file_size('tempfolder_display/bcw.opts') >= 832
	mut opts := Options{}
	display_file('tempfolder_display/bcw.opts', opts, expanded_flag: true)
}

fn test_display_classifier() ? {
	// make a classifier and save it, then display the saved classifier file
	mut opts := Options{
		command: 'make'
		bins: [3, 10]
		number_of_attributes: [8]
	}
	opts.outputfile_path = 'tempfolder_display/classifierfile'
	mut ds := load_file('datasets/developer.tab')
	mut cl := make_classifier(ds, opts)
	display_file(opts.outputfile_path, opts)
}

fn test_display_analyze_result() ? {
	// analyze a dataset file, save the result, then display
	mut opts := Options{
		command: 'analyze'
		outputfile_path: 'tempfolder_display/analyze_result'
	}
	_ = analyze_dataset(load_file('datasets/UCI/anneal.arff'), opts)
	display_file(opts.outputfile_path, opts)
}

fn test_display_ranking_result() ? {
	// rank a dataset file, save the result, then display
	mut opts := Options{
		command: 'rank'
		outputfile_path: 'tempfolder_display/rank_result'
	}
	_ = rank_attributes(load_file('datasets/UCI/anneal.arff'), opts)
	display_file(opts.outputfile_path, opts)
}

fn test_display_validate_result() ? {
	// validate a dataset file, save the result, then display
	mut opts := Options{
		command: 'make'
	}
	opts.datafile_path = 'datasets/bcw350train'
	mut ds := load_file(opts.datafile_path)
	cl := make_classifier(ds, opts)
	opts.outputfile_path = 'tempfolder_display/validate_result'
	opts.testfile_path = 'datasets/bcw174validate'
	_ = validate(cl, opts)!
	display_file(opts.outputfile_path, opts)
}

fn test_display_verify_result() ? {
	// verify a dataset file, save the result, then display
	mut opts := Options{
		datafile_path: 'datasets/bcw350train'
		testfile_path: 'datasets/bcw174test'
		outputfile_path: 'tempfolder_display/verify_result'
		command: 'verify'
		number_of_attributes: [5]
		concurrency_flag: true
	}
	// mut ds := load_file(opts.datafile_path)
	// cl := make_classifier(ds, opts)
	_ = verify(opts)
	display_file(opts.outputfile_path, opts)
	// repeat with expanded flag set
	display_file(opts.outputfile_path, opts, expanded_flag: true)
}

fn test_display_cross_result() ? {
	// cross-validate a dataset file, save the result, then display
	mut opts := Options{
		command: 'cross'
		number_of_attributes: [4]
		bins: [12]
		folds: 5
		repetitions: 0
		random_pick: false
		concurrency_flag: true
	}
	ds := load_file('datasets/UCI/segment.arff')
	opts.outputfile_path = 'tempfolder_display/cross_result'
	_ = cross_validate(ds, opts)
	display_file(opts.outputfile_path, opts)
	opts.folds = 10
	opts.repetitions = 10
	opts.random_pick = true
	_ = cross_validate(ds, opts)
	display_file(opts.outputfile_path, opts, expanded_flag: true)
}

fn test_display_explore_result_cross() ? {
	mut opts := Options{
		command: 'explore'
		datafile_path: 'datasets/UCI/iris.arff'
		bins: [2, 3]
		number_of_attributes: [2, 3]
		concurrency_flag: true
		outputfile_path: 'tempfolder_display/explore_result'
	}
	mut ds := load_file(opts.datafile_path)
	_ = explore(ds, opts)
	display_file(opts.outputfile_path, opts, show_flag: true)
	// repeat with expanded flag set
	display_file(opts.outputfile_path, opts, expanded_flag: true)

	// repeat with purge flag set
	opts.purge_flag = true
	_ = explore(ds, opts)
	display_file(opts.outputfile_path, opts, show_flag: true)
	display_file(opts.outputfile_path, opts, expanded_flag: true)

	// repeat for a binary class dataset
	opts.number_of_attributes = [0]
	opts.datafile_path = 'datasets/bcw174test'
	opts.purge_flag = false
	ds = load_file(opts.datafile_path)
	_ = explore(ds, opts)
	display_file(opts.outputfile_path, opts, show_flag: true)
	display_file(opts.outputfile_path, opts, expanded_flag: true, graph_flag: true)

	// repeat with purge flag set
	opts.purge_flag = true
	ds = load_file(opts.datafile_path)
	_ = explore(ds, opts)
	display_file(opts.outputfile_path, opts, show_flag: true)
	display_file(opts.outputfile_path, opts, expanded_flag: true)
}

fn test_display_explore_result_verify() ? {
	mut opts := Options{
		command: 'explore'
		datafile_path: 'datasets/soybean-large-train.tab'
		testfile_path: 'datasets/soybean-large-test.tab'
		bins: [2, 6]
		number_of_attributes: [12, 15]
		concurrency_flag: true
		outputfile_path: 'tempfolder_display/explore_result'
	}
	mut ds := load_file(opts.datafile_path)
	_ = explore(ds, opts)
	display_file(opts.outputfile_path, opts, show_flag: true)
	display_file(opts.outputfile_path, opts, expanded_flag: true)

	// repeat with purge flag set
	opts.purge_flag = true
	_ = explore(ds, opts, show_flag: true)
	display_file(opts.outputfile_path, opts, show_flag: true)
	display_file(opts.outputfile_path, opts, expanded_flag: true)

	// repeat for a binary class dataset
	opts.datafile_path = 'datasets/bcw350train'
	opts.testfile_path = 'datasets/bcw174test'
	opts.purge_flag = false
	opts.number_of_attributes = [0]
	ds = load_file(opts.datafile_path)
	_ = explore(ds, opts)
	display_file(opts.outputfile_path, opts, show_flag: true)
	display_file(opts.outputfile_path, opts, expanded_flag: true)

	// repeat with purge flag set
	opts.purge_flag = true
	_ = explore(ds, opts)
	display_file(opts.outputfile_path, opts, show_flag: true)
	display_file(opts.outputfile_path, opts, expanded_flag: true)
}
