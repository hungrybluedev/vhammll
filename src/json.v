// json.v

module vhammll

import os
import json

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

// save_json_file
pub fn save_json_file[T](u T, path string) {
	// s := json.encode(u)
	s := ''
	mut f := os.open_file(path, 'w') or { panic(err.msg()) }
	f.write_string(s) or { panic(err.msg()) }
	f.close()
}

// append_json_file
fn append_json_file[T](u T, path string) {
	// println(path)
	mut f := os.open_append(path) or { panic(err.msg()) }
	// f.write_string(json.encode(u) + '\n') or { panic(err.msg()) }
	f.close()
}

// read_multiple_opts
fn read_multiple_opts(path string) ![]ClassifierSettings {
	mut s := os.read_lines(path.trim_space()) or { panic('failed to open ${path}') }
	// dump(s)
	// r := MultipleClassifierSettingsFileStruct{
	// 	multiple_classifier_settings: s.map(json.decode(ClassifierSettings, it)!)
	// }
	// dump(r)
	// return r.multiple_classifier_settings
	return []ClassifierSettings
}