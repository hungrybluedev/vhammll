// display.v
module vhammll

import os
import json
// 

// display_file displays on the console, a results file as produced by other
// hamnn functions.
// ```sh
// display_file('path_to_saved_results_file', expanded_flag: true)
// Output options:
// expanded_flag: display additional information on the console, including
// 	a confusion matrix for cross-validation or verification operations;
// graph_flag: generates plots for display in the default web browser.
// ```
pub fn display_file(path string, opts Options) {
	// determine what kind of file, then call the appropriate functions in show and plot
	s := os.read_file(path.trim_space()) or { panic('failed to open ${path}') }
	match true {
		s.contains('"struct_type":".ExploreResult"') {
			// mut opts := Options{
			// 	DisplaySettings: settings
			// }
			mut saved_er := json.decode(ExploreResult, s) or { panic('Failed to parse json') }
			show_explore_header(saved_er, opts.DisplaySettings)
			for mut result in saved_er.array_of_results {
				result.DisplaySettings = opts.DisplaySettings
				show_explore_line(result)
			}
			show_explore_trailer(saved_er, opts)
			if opts.graph_flag {
				// println(saved_er)
				plot_explore(saved_er, opts)
				plot_roc(saved_er, opts)
			}
			if opts.append_settings_flag {
				// save the settings for the explore results with the
				// highest balanced accuracy, true positives, and true
				// negatives
				append_explore_settings_to_file(saved_er, opts)
			}
		}
		s.contains('"struct_type":".Classifier"') {
			saved_cl := json.decode(Classifier, s) or { panic('Failed to parse json') }
			show_classifier(saved_cl)
		}
		s.contains('"struct_type":".RankingResult"') {
			saved_rr := json.decode(RankingResult, s) or { panic('Failed to parse json') }
			show_rank_attributes(saved_rr)
			if opts.graph_flag {
				plot_rank(saved_rr)
			}
		}
		s.contains('"struct_type":".AnalyzeResult"') {
			saved_ar := json.decode(AnalyzeResult, s) or { panic('Failed to parse json') }
			show_analyze(saved_ar)
		}
		s.contains('"struct_type":".ValidateResult"') {
			saved_valr := json.decode(ValidateResult, s) or { panic('Failed to parse json') }
			show_validate(saved_valr)
		}
		s.contains('"struct_type":".CrossVerifyResult"') && s.contains('"command":"verify"') {
			// mut opts := Options{
			// 	DisplaySettings: settings
			// }
			mut saved_vr := json.decode(CrossVerifyResult, s) or { panic('Failed to parse json') }
			// saved_vr.DisplaySettings = settings
			show_verify(saved_vr, opts)
		}
		s.contains('"struct_type":".CrossVerifyResult"') {
			saved_vr := json.decode(CrossVerifyResult, s) or { panic('Failed to parse json') }
			show_crossvalidation(saved_vr)
			if opts.append_settings_flag {
				append_cross_settings_to_file(saved_vr, opts)
			}
		}
		s.contains('"classifier_options":') {
			multiple_classifiers_array := read_multiple_opts(path) or {
				panic('read_multiple_opts failed')
			}
			multiple_options := MultipleOptions{
				classifier_indices: []int{len: multiple_classifiers_array.multiple_classifiers.len, init: index}
			}
			show_multiple_classifiers_options(multiple_options, multiple_classifiers_array)
		}
		else {
			println('File type not recognized!')
		}
	}
}
