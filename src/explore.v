// explore.v
module vhammll

// explore runs a series of cross-validations or verifications,
// over a range of attributes and a range of binning values.
// ```sh
// Options (also see the Options struct):
// bins: range for binning or slicing of continuous attributes;
// uniform_bins: same number of bins for all continuous attributes;
// number_of_attributes: range for attributes to include;
// exclude_flag: excludes missing values when ranking attributes;
// weighting_flag: nearest neighbor counts are weighted by
// 	class prevalences;
// folds: number of folds n to use for n-fold cross-validation (default
// 	is leave-one-out cross-validation);
// repetitions: number of times to repeat n-fold cross-validations;
// random-pick: choose instances randomly for n-fold cross-validations.
// Output options:
// show_flag: display results on the console;
// expanded_flag: display additional information on the console, including
// 	a confusion matrix for each explore step;
// graph_flag: generate plots of Receiver Operating Characteristics (ROC)
// 	by attributes used; ROC by bins used, and accuracy by attributes
//	used.
// outputfile_path: saves the result to a file.
// ```
pub fn explore(ds Dataset, opts Options, disp DisplaySettings) ExploreResult {
	// println(opts.classifier_indices)
	mut ex_opts := opts
	mut results := ExploreResult{
		LoadOptions: ds.LoadOptions
		path: opts.datafile_path
		testfile_path: opts.testfile_path
		Parameters: opts.Parameters
		DisplaySettings: disp
		AttributeRange: get_attribute_range(opts.number_of_attributes,
			ds.useful_continuous_attributes.len + ds.useful_discrete_attributes.len)
		pos_neg_classes: get_pos_neg_classes(ds.class_counts)
		args: opts.args
	}
	mut result := CrossVerifyResult{
		pos_neg_classes: results.pos_neg_classes
	}
	// mut attribute_max := ds.useful_continuous_attributes.len + ds.useful_discrete_attributes.len
	// if there are no useful continuous attributes, skip the binning
	if ds.useful_continuous_attributes.len == 0 {
		ex_opts.bins = [0]
	}
	results.binning = get_binning(ex_opts.bins)
	binning := results.binning
	if opts.command == 'explore' && (disp.show_flag || disp.expanded_flag) {
		// show_explore_header(pos_neg_classes, binning, opts)
		show_explore_header(results, results.DisplaySettings)
	}
	mut atts := results.start
	// mut cl := Classifier{}
	mut array_of_results := []CrossVerifyResult{}
	// mut plot_data := [][]PlotResult{}

	for atts <= results.end {
		ex_opts.number_of_attributes = [atts]
		mut bin := binning.lower
		for bin <= binning.upper {
			if ex_opts.uniform_bins {
				ex_opts.bins = [bin, bin]
			} else {
				ex_opts.bins = [1, bin]
			}
			if ex_opts.testfile_path == '' {
				result = cross_validate(ds, ex_opts, disp)
			} else {
				// cl = make_classifier(mut ds, ex_opts)
				result = verify(ex_opts)
			}
			result.bin_values = ex_opts.bins
			result.attributes_used = atts
			show_explore_line(result, results.DisplaySettings)

			array_of_results << result
			bin += binning.interval
		}
		atts += results.att_interval
	}
	results.array_of_results = array_of_results
	// results.analytics = get_explore_analytics(results)
	if opts.outputfile_path != '' {
		save_json_file(results, opts.outputfile_path)
	}
	if opts.command == 'explore' && (disp.show_flag || disp.expanded_flag) {
		show_explore_trailer(results, opts)
	}
	// println(ds.class_counts.len)
	if disp.graph_flag {
		// println('Just prior to plot_explore')
		plot_explore(results, opts)
		// println('Just after plot_explore')
		if ds.class_counts.len == 2 {
			// println('should be printing ROC here')
			plot_roc(results, opts)
		}
	}
	if opts.append_settings_flag {
		// save the settings for the explore results with the
		// highest balanced accuracy, true positives, and true
		// negatives
		append_explore_settings_to_file(results, opts)
	}
	return results
}

// append_explore_settings_to_file
fn append_explore_settings_to_file(results ExploreResult, opts Options) {
	// println('results in append_explore_settings_to_file: $results')
	mut indices := opts.classifier_indices.clone()
	if indices == [] {
		indices = []int{len: 7, init: index}
	}
	m := explore_analytics2(results)
	mut i := 0
	for _, a in m {
		if i in indices {
			// println(results.array_of_results[a.idx])
			append_json_file(ClassifierSettings{
				Parameters: results.array_of_results[a.idx].Parameters
				BinaryMetrics: results.array_of_results[a.idx].BinaryMetrics
			}, opts.settingsfile_path)
		}
		i += 1
	}
}

// get_attribute_range
fn get_attribute_range(atts []int, max int) AttributeRange {
	if atts == [0] {
		return AttributeRange{
			start: 1
			end: max
			att_interval: 1
		}
	}
	if atts.len == 1 {
		return AttributeRange{
			start: 1
			end: atts[0]
			att_interval: 1
		}
	}
	if atts.len == 2 {
		return AttributeRange{
			start: atts[0]
			end: atts[1]
			att_interval: 1
		}
	}
	return AttributeRange{
		start: atts[0]
		end: atts[1]
		att_interval: atts[2]
	}
}
