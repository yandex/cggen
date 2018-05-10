#!/usr/bin/env python
# Copyright (c) 2017 Yandex LLC. All rights reserved.
# Author: Alfred Zien <zienag@yandex-team.ru>

import common
import os
import unittest


pdf_samples_dir_path = 'test_regression/pdf_samples'
temp_dir_path = 'test_regression/temp'
images_generation_scale = 5
tolerance = 0.01


class cggen_tests(unittest.TestCase):
    @classmethod
    def setUpClass(self):
        package_path = os.path.abspath(".")
        temp_dir = os.path.abspath(temp_dir_path)
        pdfs = common.pdf_files_in_dir(pdf_samples_dir_path)

        self.context = common.prepare_for_comparison(package_path, temp_dir, 
            pdfs, images_generation_scale)
        self.context.diff_dir = os.path.join(temp_dir, "diff")


    def checkImagesEqual(self, img_name):
        diff = common.check_images_diff(
            self.context.generated_pngs[img_name], 
            self.context.reference_pngs[img_name],
            self.context.build_path, 
            diff_output_dir=self.context.diff_dir,
            image_name=img_name)
        self.assertLess(diff, tolerance)


    def test_alpha(self):
        self.checkImagesEqual('alpha')


    def test_fill(self):
        self.checkImagesEqual('fill')


    def test_gradient_radial(self):
        self.checkImagesEqual('gradient_radial')

    def test_gradient_shape(self):
        self.checkImagesEqual('gradient_shape')


    def test_gradient_three_dots(self):
        self.checkImagesEqual('gradient_three_dots')


    def test_gradient_with_alpha(self):
        self.checkImagesEqual('gradient_with_alpha')


    def test_gradient_with_mask(self):
        self.checkImagesEqual('gradient_with_mask')


    def test_gradient(self):
        self.checkImagesEqual('gradient')


    def test_lines(self):
        self.checkImagesEqual('lines')


    def test_shapes(self):
        self.checkImagesEqual('shapes')

    def test_group_opacity(self):
        self.checkImagesEqual('group_opacity')


    def test_dashes(self):
        self.checkImagesEqual('dashes')


    def test_caps_joins(self):
        self.checkImagesEqual('caps_joins')


    def test_underlying_object_with_tiny_alpha(self):
        self.checkImagesEqual('underlying_object_with_tiny_alpha')


    def test_nested_transparent_group(self):
        self.checkImagesEqual('nested_transparent_group')


def main():
    unittest.main()

if __name__ == '__main__':
    main()
