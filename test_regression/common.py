#!/usr/bin/env python
# Copyright (c) 2018 Yandex LLC. All rights reserved.
# Author: Alfred Zien <zienag@yandex-team.ru>

import argparse
import os
import shutil
import subprocess
import sys
from time import time


class Stopwatch:
    def __init__(self):
        self.time = time()
    
    def reset(self):
        now = time()
        t = now - self.time
        self.time = now
        return t


class ComparionContext:
    def __init__(self, generated_pngs, reference_pngs, build_path):
        self.generated_pngs = generated_pngs
        self.reference_pngs = reference_pngs
        self.build_path = build_path


def prepare_for_comparison(package_path, working_path, pdfs, scale):
    header_path = os.path.join(working_path, 'gen.h')
    impl_path = os.path.join(working_path, 'gen.m')
    caller_path = os.path.join(working_path, 'main.m')
    bin_path = os.path.join(working_path, 'bin')
    reference_png_path = os.path.join(working_path, 'reference_png')
    png_path = os.path.join(working_path, 'png')

    _clean_dir(working_path)
    os.mkdir(reference_png_path)
    os.mkdir(png_path)

    build_path = _get_build_path(package_path)

    stopwatch = Stopwatch()

    _compile_package(package_path)
    print "Compiled package in", stopwatch.reset()

    _run_cggen(build_path, header_path, impl_path, caller_path, png_path, scale, pdfs)
    print "cggen invoked in", stopwatch.reset()

    _convert_pdf_to_png(build_path, reference_png_path, scale, pdfs)
    print "Ref PNG generated in", stopwatch.reset()

    _compile([impl_path, caller_path], bin_path)
    print "Clang invocation in", stopwatch.reset()

    subprocess.check_call([bin_path])
    print "PNG Generated in", stopwatch.reset()

    generated_pngs = {
        _filename_without_extension(p): p 
        for p in _png_files_in_dir(png_path)
        }
    reference_pngs = {
        _filename_without_extension(p): p 
        for p in _png_files_in_dir(reference_png_path)
        }

    return ComparionContext(generated_pngs, reference_pngs, build_path)


def check_images_diff(img1_path, img2_path, build_path, 
    diff_output_dir=None, image_name=None):
    """runs png-fuzzy-compare on two images"""

    diff_tool = os.path.join(build_path, 'png-fuzzy-compare')
    diff_command = [
        diff_tool,
        '--first-image',
        img1_path,
        '--second-image',
        img2_path,
    ]

    if diff_output_dir and image_name:
        assert(image_name)
        if not os.path.exists(diff_output_dir):
            os.mkdir(diff_output_dir)
        diff_command += [
            '--output-image-diff',
            os.path.join(diff_output_dir, image_name + '_diff.png'),
            '--output-ascii-diff',
            os.path.join(diff_output_dir, image_name + '_diff.txt'),
            ]
    output = subprocess.check_output(diff_command)
    return float(output)


def pdf_files_in_dir(path):
    return _files_from_dir(path, "pdf")


def _compile_package(path):
    compile_cggen_command = [
        "swift", "build", "--configuration", "release", "--package-path", path
        ]
    subprocess.check_call(compile_cggen_command)


def _get_build_path(swift_package_path):
    get_build_path_command = [
        "swift", "build", "--configuration", "release", "--show-bin-path", 
        "--package-path", swift_package_path
        ]
    bin_path = subprocess.check_output(get_build_path_command)[:-1]
    return os.path.join(bin_path)


def _files_from_dir(path, extension):
    return [ os.path.abspath(os.path.join(path, p))
        for p in os.listdir(path)
        if p.endswith(extension) ]


def _png_files_in_dir(path):
    return _files_from_dir(path, "png")


def _filename_without_extension(path):
    name = os.path.basename(path)
    return os.path.splitext(name)[0]


def _clean_dir(path):
    if os.path.exists(path):
        shutil.rmtree(path)
    os.mkdir(path)


def _run_cggen(build_path, header_path, impl_path, caller_path, 
    png_path, scale, pdfs):
    """runs cggen on with supplied arguments"""

    cggen_tool = os.path.join(build_path, 'cggen')
    cggen_command = [
        cggen_tool,
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
        str(scale)
        ] + pdfs
    subprocess.check_call(cggen_command)


def _convert_pdf_to_png(build_path, png_path, scale, pdfs):
    pdf_to_png_conversion_tool = os.path.join(build_path, 'pdf-to-png')
    reference_pngs_command = [
        pdf_to_png_conversion_tool,
        '--out',
        png_path,
        '--scale',
        str(scale),
        ] + pdfs
    subprocess.check_call(reference_pngs_command)


def _sdk_path():
    sdk_path_command = ['xcrun', '--sdk', 'macosx', '--show-sdk-path']
    return subprocess.check_output(sdk_path_command)[:-1]


def _compile(files, output):
    clang_invoc = [
        'clang',
        '-Weverything',
        '-Werror',
        '-isysroot',
        _sdk_path(),
        '-framework',
        'CoreGraphics',
        '-framework',
        'Foundation',
        '-framework',
        'ImageIO',
        '-framework',
        'CoreServices',
        '-o',
        output,
    ] + files
    subprocess.check_call(clang_invoc)

