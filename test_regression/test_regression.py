#!/usr/bin/env python
# Copyright (c) 2017 Yandex LLC. All rights reserved.
# Author: Alfred Zien <zienag@yandex-team.ru>

import os
import shutil
import subprocess
import unittest
from time import time


pdf_samples_dir_path = 'test_regression/pdf_samples'
temp_dir_path = 'test_regression/temp'
images_generation_scale = '5'
tolerance = 0.01

def compile_cggen():
    subprocess.check_call(["swift", "build", "--configuration", "release"])


def get_build_path():
    bin_path = subprocess.check_output(["swift", "build", "--configuration", "release", "--show-bin-path"])[:-1]
    return os.path.join(bin_path)


def pdf_samples():
    return [ os.path.abspath(os.path.join(pdf_samples_dir_path, p))
        for p in os.listdir(pdf_samples_dir_path)
        if p.endswith("pdf") ]


def png_files_in_dir(dir):
    return [os.path.join(dir, p) for p in os.listdir(dir) if p.endswith("png")]


def sdk_path():
    return subprocess.check_output(['xcrun', '--sdk', 'macosx', '--show-sdk-path'])[:-1]


def filename_wo_ext_from_dir(dir):
    name = os.path.basename(dir)
    return os.path.splitext(name)[0]


class cggen_tests(unittest.TestCase):
    @classmethod
    def setUpClass(self):

        t0 = time()
        compile_cggen()
        temp_dir = os.path.abspath(temp_dir_path)
        if os.path.exists(temp_dir):
            shutil.rmtree(temp_dir)
        os.mkdir(temp_dir)
        build_path = get_build_path()
        cggen_path = os.path.join(build_path, 'cggen')
        diff_tool_path = os.path.join(build_path, 'png-fuzzy-compare')
        pdf_to_png_conversion_tool = os.path.join(build_path, 'pdf-to-png')
        temp_dir = temp_dir
        header_path = os.path.join(temp_dir, 'gen.h')
        impl_path = os.path.join(temp_dir, 'gen.m')
        caller_path = os.path.join(temp_dir, 'main.m')
        bin_path = os.path.join(temp_dir, 'bin')
        reference_png_path = os.path.join(temp_dir, 'reference_png')
        if not os.path.exists(reference_png_path):
            os.mkdir(reference_png_path)
        png_path = os.path.join(temp_dir, 'png')
        if not os.path.exists(png_path):
            os.mkdir(png_path)

        t_cggen_compile = time()
        print "Compiled cggen in", t_cggen_compile - t0

        cggen_invoc = [
                  cggen_path,
                  '--objc-header',
                  header_path,
                  '--objc-header-import-path',
                  header_path,
                  '--objc-impl',
                  impl_path,
                  '--objc-caller-path',
                  caller_path,
                  '--caller-png-output',
                  png_path,
                  '--caller-scale',
                  images_generation_scale
              ] + pdf_samples()
        subprocess.check_call(cggen_invoc)

        t_cggen_invoc = time()
        print "cggen invoked in", t_cggen_invoc - t_cggen_compile

        reference_pngs_invoc = [
            pdf_to_png_conversion_tool,
            '--out',
            reference_png_path,
            '--scale',
            images_generation_scale,
        ] + pdf_samples()
        subprocess.check_call(reference_pngs_invoc)

        t_png_generated = time()
        print "Ref PNG generated", t_png_generated - t_cggen_invoc

        clang_invoc = [
            'clang',
            '-Weverything',
            '-Werror',
            '-isysroot',
            sdk_path(),
            '-framework',
            'CoreGraphics',
            '-framework',
            'Foundation',
            '-framework',
            'ImageIO',
            '-framework',
            'CoreServices',
            impl_path,
            caller_path,
            '-o',
            bin_path,
        ]
        subprocess.check_call(clang_invoc)
        t_clang_invoc = time()
        print "Clang invocation:", t_clang_invoc - t_png_generated

        subprocess.check_call([bin_path])
        t_png_gen = time()
        print "PNG Generated:", t_png_gen - t_clang_invoc

        self.temp_dir = temp_dir
        self.diff_tool_path = diff_tool_path
        self.pngs = {filename_wo_ext_from_dir(p): p for p in png_files_in_dir(png_path)}
        self.reference_pngs = {filename_wo_ext_from_dir(p): p for p in png_files_in_dir(reference_png_path)}


    def checkImagesEqual(self, img_name):
        path = self.pngs[img_name]
        reference_path = self.reference_pngs[img_name]
        diff_output_path = os.path.join(self.temp_dir, "diff")
        if not os.path.exists(diff_output_path):
            os.mkdir(diff_output_path)
        diff_call = [
            self.diff_tool_path,
            '--first-image',
            path,
            '--second-image',
            reference_path,
            '--output-image-diff',
            os.path.join(diff_output_path, img_name + '_diff.png'),
            '--output-ascii-diff',
            os.path.join(diff_output_path, img_name + '_diff.txt'),
        ]
        output = subprocess.check_output(diff_call)
        self.assertLess(float(output), tolerance)


    def test_alpha(self):
        self.checkImagesEqual('alpha')


    def test_fill(self):
        self.checkImagesEqual('fill')


    def test_gradient_shape(self):
        self.checkImagesEqual('gradient_shape')


    @unittest.expectedFailure
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


def main():
    unittest.main()

if __name__ == '__main__':
    main()
