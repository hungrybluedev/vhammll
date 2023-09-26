// load_older.v
module vhammll

import os

// load_orange_older_file loads from a file into a Dataset struct
fn load_orange_older_file(path string) Dataset {
	content := os.read_lines(path.trim_space()) or { panic('failed to open ${path}') }
	mut ds := Dataset{
		path: path
		attribute_names: extract_words(content[0])
		attribute_types: extract_words(content[1])
		attribute_flags: extract_words(content[2])
		data: transpose(content[3..].map(extract_words(it)))
	}
	attr_count := ds.attribute_names.len
	ds.attribute_types = pad_string_array_to_length(mut ds.attribute_types, attr_count)
	ds.attribute_flags = pad_string_array_to_length(mut ds.attribute_flags, attr_count)
	ds.inferred_attribute_types = infer_attribute_types_older(ds)
	ds.Class = set_class_struct(ds)

	ds.useful_continuous_attributes = get_useful_continuous_attributes(ds)
	ds.useful_discrete_attributes = get_useful_discrete_attributes(ds)
	return ds
}

// infer_attribute_types_older gets inferred attribute types for orange-older files
// returns an array to plug into the Dataset struct
/*
For orange-older:
in the second line (ds.attribute_types):
  	'd' or 'discrete' or a list of values: denotes a discrete attribute
  	'c' or 'continuous': denotes a continuous attribute
  	'string' denotes a string variable, which we ignore
  	'basket': these are continuous-valued meta attributes; ignore
  	it may also contain a string of values separated by spaces. Use these
  	as the values for a discrete attribute.
  the third line (ds.attribute_flags) contains optional flags:
  	'i' or 'ignore'
  	'c' or 'class': there can only be one class attribute. If none is found,
  	 use the last attribute as the class attribute.
  	'm' or 'meta': meta attribute, eg weighting information; ignore
  	'-dc' followed by a value: indicates how a don't care is represented.
*/
fn infer_attribute_types_older(ds Dataset) []string {
	mut inferred_attribute_types := []string{}
	mut attr_type := ''
	mut attr_flag := ''
	mut inferred := ''
	for i in 0 .. ds.attribute_names.len {
		attr_type = ds.attribute_types[i]
		attr_flag = ds.attribute_flags[i]
		if attr_flag in ['c', 'class'] {
			inferred = 'c'
		} else if attr_type in ['d', 'discrete'] {
			inferred = 'D'
		} else if attr_type in ['c', 'continuous'] {
			inferred = 'C'
		} else if attr_type in ['string', 'basket'] || attr_flag in ['i', 'ignore'] {
			inferred = 'i'
		}
		// if the entry contains a list of items separated by spaces
		else if attr_type.contains(' ') {
			inferred = 'D'
		} else if attr_type == '' && attr_flag == '' {
			inferred = infer_type_from_data(ds.data[i])
		} else {
			panic('unrecognized attribute type "${attr_type}" for attribute "${ds.attribute_names[i]}"')
		}
		inferred_attribute_types << inferred
	}
	return inferred_attribute_types
}

// pad_string_array_to_length adds empty strings to arr to extend to length l
fn pad_string_array_to_length(mut arr []string, l int) []string {
	if arr.len >= l {
		return arr
	}
	for {
		arr << ['']
		if arr.len >= l {
			break
		}
	}
	return arr
}
