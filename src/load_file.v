module vhammll

import os
import strconv
import math
import json
import regex

// load_file returns a struct containing the datafile's contents,
// suitable for generating a classifier
//
// Example:
// ```sh
// ds := load_file('datasets/iris.tab')
// ```

pub fn load_file(path string, opts LoadOptions) Dataset {
	// println(path)
	// println(file_type(path))
	return match file_type(path) {
		'orange_newer' { load_orange_newer_file(path, opts) }
		'orange_older' { load_orange_older_file(path) }
		'arff' { load_arff_file(path) }
		'UKDA' { load_orange_newer_file(path, opts) }
		'csv' { load_csv_file(path) }
		else { panic('unrecognized file type') }
	}
}

// file_type returns a string identifying how a dataset is structured or
// formatted, eg 'orange_newer', 'orange_older', 'arff', or 'csv'.
// On the assumption that an 'orange_older' file will always identify 
// a class attribute by having 'c' or 'class' in the third header line,
// all other tab-delimited datafiles will be typed as 'orange_newer'.
//
// Example:
// ```sh
// assert file_type('datasets/iris.tab') == 'orange_older'
// ```
pub fn file_type(path string) string {
	header := os.read_lines(path.trim_space()) or { panic('Failed to open ${path} in file_type()') }
	return match true {
		os.file_ext(path) == '.arff' { 'arff' }
		os.file_ext(path) == '.csv' { 'csv' }
		header[2].split('\t').any(it == 'c' || it == 'class' ) { 'orange_older' }
		else { 'orange_newer' }
	}
	// if os.file_ext(path) == '.arff' {
	// 	return 'arff'
	// }
	// if path.contains('UKDA') {
	// 	return 'UKDA'
	// }
	// if os.file_ext(path) == '.csv' {
	// 	return 'csv'
	// }
	// 
	// if header[2].split('\t').any(it == 'c' || it == 'class') {
	// 	return 'orange_older'
	// }
	// return 'orange_newer'
}

// load_classifier_file loads a file generated by make_classifier();
// returns a Classifier struct.
//
// Example:
// ```sh
// cl := load_classifier_file('tempfolder/saved_classifier.txt')
// ```
pub fn load_classifier_file(path string) !Classifier {
	s := os.read_file(path.trim_space()) or { panic('failed to open ${path}') }
	cl := json.decode(Classifier, s) or { panic('Failed to parse json') }
	return cl
}

// load_instances_file loads a file generated by validate()
// or query(), and returns it as a struct, suitable for
// appending to a classifier.
//
// Example:
// ````sh
// instances := load_instances_file('tempfolder/saved_validate_result.txt')
// ```
pub fn load_instances_file(path string) !ValidateResult {
	// mut instances := ValidateResult{}
	// mut s := ''
	s := os.read_file(path.trim_space()) or { panic('failed to open ${path}') }
	// println(s)
	instances := json.decode(ValidateResult, s) or { panic('Failed to parse json') }
	return instances
}

fn extract_words(line string) []string {
	mut splitted := []string{}
	for tab_splitted in line.split('\t') {
		splitted << tab_splitted
	}
	// println('splitted: $splitted')
	return splitted
}

// infer_type_from_data
fn infer_type_from_data(values []string) string {
	no_missing_values := values.filter(it !in missings)
	// if no data, 'i'
	if no_missing_values == [] {
		return 'i'
	}
	// if all the elements are identical, then the attribute is useless, so 'i'
	if uniques(no_missing_values).len == 1 {
		return 'i'
	}
	// else, examine individual data elements
	mut re := regex.regex_opt(r'[g-zG-Z]+') or { panic(err) }
	// if any nonmissing element has nonnumeric values
	for element in no_missing_values {
		start, _ := re.find(element)
		if start >= 0 { // ie contains nonnumeric
			return 'D'
		}
	}
	// at this point, we assume all the values are numeric
	// test that non-missing integer values are all in the range for discrete attributes
	// verify that there are no non-integer values
	if no_missing_values.any(it.contains('.')) {
		return 'C'
	}
	if no_missing_values.map(it.int()).all(it in integer_range_for_discrete) {
		return 'D'
	}
	return 'C'
}

// get_useful_continuous_attributes
fn get_useful_continuous_attributes(ds Dataset) map[int][]f32 {
	// initialize the values of the result to -max_f32, to indicate missing values
	// mut min_value := f32(0.)
	// mut max_value := f32{0.}
	mut cont_att := map[int][]f32{}
	for i in 0 .. ds.attribute_names.len {
		if ds.inferred_attribute_types[i] == 'C' && string_element_counts(ds.data[i]).len != 1 {
			nums := ds.data[i].map(fn (w string) f32 {
				if w in missings { return -math.max_f32
				 } else { return f32(strconv.atof_quick(w))
				 }
			})
			cont_att[i] = nums
		}
	}
	return cont_att
}

// get_useful_discrete_attributes
fn get_useful_discrete_attributes(ds Dataset) map[int][]string {
	mut disc_att := map[int][]string{}
	for i in 0 .. ds.attribute_names.len {
		if ds.inferred_attribute_types[i] == 'D' && string_element_counts(ds.data[i]).len != 1 {
			disc_att[i] = ds.data[i]
		}
	}
	return disc_att
}

// set_class_struct
fn set_class_struct(ds Dataset) Class {
	mut i := identify_class_attribute(ds.inferred_attribute_types)
	// i == -1 if no class attribute found
	if i == -1 {
		if ds.path.contains('UKDA') {
			return Class{}
		} else {
			// make the last attribute the class attribute
			i = ds.attribute_names.len - 1
		}
	}
	class_counts := string_element_counts(ds.data[i])
	mut cl := Class{
		class_name: ds.attribute_names[i]
		class_values: ds.data[i]
		// class_counts: string_element_counts(ds.data[i])
		class_counts: class_counts
		classes: class_counts.keys()
	}
	return cl
}

// identify_class_attribute returns the index for the class attribute; if
// none found, returns -1
fn identify_class_attribute(inferred_attribute_types []string) int {
	for i, val in inferred_attribute_types {
		if val == 'c' {
			return i
		}
	}
	return -1
}
