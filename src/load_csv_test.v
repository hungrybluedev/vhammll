// load_csv_test.v

module vhammll

// import os

fn test_load_csv_file() {
	mut ds := load_csv_file('datasets/play_tennis.csv')
	assert ds.Class == Class{
		class_name: 'play'
		classes: ['No', 'Yes']
		class_values: ['No', 'No', 'Yes', 'Yes', 'Yes', 'No', 'Yes', 'No', 'Yes', 'Yes', 'Yes',
			'Yes', 'Yes', 'No']
		class_counts: {
			'No':  5
			'Yes': 9
		}
		lcm_class_counts: 0
		postpurge_class_counts: {}
		postpurge_lcm_class_counts: 0
	}
	assert ds.inferred_attribute_types == ['i', 'D', 'D', 'D', 'D', 'c']
}
