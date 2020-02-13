#!/usr/bin/env python

import argparse
import common
import os
import sys


def main(args):
    pdfs = common.pdf_files_in_dir(args.dir)
    context = common.prepare_for_comparison(args.cggen_package,
        args.result_dir, pdfs, args.scale)

    total = len(context.generated_pngs)
    current = 0
    errors = 0
    for key in context.generated_pngs:
        img = context.generated_pngs[key]
        ref_img = context.reference_pngs[key]
        sys.stdout.write("\033[K")
        print '[{}/{}] Checking {}...{}\r'.format(current, total, key, ' ' * 10),
        diff = common.check_images_diff(img, ref_img, context.build_path)
        if  diff > args.tolerance:
            sys.stdout.write("\033[K")
            print "OUT OF TOLERANCE: {}, diff: {}".format(key, diff)
            errors += 1
        current += 1
    print "[{}/{}] Complete, {} images found with difference out of tolerance".format(total, total, errors)


def parse_arguments():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        '--dir', required=True,
        help='path to directory with pdfs')
    parser.add_argument(
        '--result-dir', required=True,
        help='path to directory where results will be stored')
    parser.add_argument(
        '--tolerance', 
        type=float, 
        default=0.01, 
        help='acceptable root mean square of each pixel difference')
    parser.add_argument(
        '--scale', 
        type=int, 
        default=3, 
        help='scale at which images will be generated and compared')
    parser.add_argument(
        '--cggen-package', required=True, 
        help='cggen package path')
    return parser.parse_args()


if __name__ == '__main__':
    main(parse_arguments())
