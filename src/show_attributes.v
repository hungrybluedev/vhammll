// show_attributes.v
// The possibility to show a list of trained attributes applies to make_classifier,
// verify, validate, and query operations. It does not apply to cross-validation,
// because the attributes used may change from one fold or repetition to the next.
//
// It is also possible to show the attributes for the individual classifier settings
// in a classifier settings (`.opts`) file, but since the list of trained attributes
// is not included in a settings file, they will need to be generated by creating
// classifiers for each setting.	

module vhammll

// import arrays
// import strings

fn show_classifier_attributes(cl Classifier) {	
	show_trained_attributes(cl.trained_attributes)
}

fn show_attributes_for_verify(result CrossVerifyResult) {
	if result.multiple_flag {
		show_trained_attributes_for_multiple_classifiers(result)
	} else {
		show_trained_attributes_for_one_classifier(result)
	}
}

fn show_trained_attributes_for_one_classifier(result CrossVerifyResult) {
	println(g_b('Trained attributes for classifier on dataset ${result.datafile_path}'))
}

fn show_trained_attributes(atts_map map[string]TrainedAttribute) {
println(b_u('Index  Attribute                   Type  Rank Value   Uniques       Min        Max  Bins'))
	for attr, val in atts_map {
		println('${val.index:5}  ${attr:-27} ${val.attribute_type:-4}  ${val.rank_value:10.2f}' +
			if val.attribute_type == 'C' { '          ${val.minimum:10.2f} ${val.maximum:10.2f} ${val.bins:5}' } else { '      ${val.translation_table.len:4}' })
	}
}

fn show_trained_attributes_for_multiple_classifiers(result CrossVerifyResult) {
	for idx in result.classifier_indices {
		println(g_b('Trained attributes for classifier ${idx} on dataset ${result.datafile_path}'))
		show_trained_attributes(result.trained_attribute_maps_array[idx])
	}
}

// fn show_trained_attributes_for_multiple_classifier_settings(classifier_settings []ClassifierSettings, classifier_indices []int) {
// 	for idx in classifier_indices {
// 		println(g_b('Trained attributes for classifier ${idx} on dataset ${classifier_settings[0].datafile_path}'))
// 		// show_trained_attributes(classifier_settings[idx].trained_attributes)
// 	}
// }
