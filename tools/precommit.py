#!/usr/bin/env python

# Copyright 2016-present Samsung Electronics Co., Ltd. and other contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from __future__ import print_function

import argparse
import sys
import os
import json
from common_py import path
from common_py.system.filesystem import FileSystem as fs
from common_py.system.executor import Executor as ex
from common_py.system.platform import Platform
from check_tidy import check_tidy

TESTS=['host', 'rpi2', 'nuttx', 'misc', 'artik10']
BUILDTYPES=['debug', 'release']
NUTTXTAG = 'nuttx-7.19'

def get_config():
    config_path = path.BUILD_CONFIG_PATH
    with open(config_path, 'r') as f:
        config = json.loads(f.read().encode('ascii'))
    return config


def parse_option():
    parser = argparse.ArgumentParser(
         description='IoT.js pre-commit script.',
         epilog='If no arguments are given, runs full test.')
    parser.add_argument('--test', choices=TESTS, action='append')
    parser.add_argument('--buildtype', choices=BUILDTYPES, action='append')
    parser.add_argument('--buildoptions', action='store', default='',
                        help='A comma separated list of extra buildoptions')

    option = parser.parse_args(sys.argv[1:])
    if option.test is None:
        option.test = TESTS
    if option.buildtype is None:
        option.buildtype = BUILDTYPES
    return option


def setup_nuttx_root(nuttx_root):
    # Step 1
    fs.maybe_make_directory(nuttx_root)
    fs.chdir(nuttx_root)
    if not fs.exists('nuttx'):
        ex.check_run_cmd('git', ['clone',
                                 'https://bitbucket.org/nuttx/nuttx.git'])
    fs.chdir('nuttx')
    ex.check_run_cmd('git', ['checkout', NUTTXTAG])
    fs.chdir('..')

    if not fs.exists('apps'):
        ex.check_run_cmd('git', ['clone',
                                 'https://bitbucket.org/nuttx/apps.git'])
    fs.chdir('apps')
    ex.check_run_cmd('git', ['checkout', NUTTXTAG])
    fs.chdir('..')

    # Step 2
    fs.maybe_make_directory(fs.join(nuttx_root, 'apps', 'system', 'iotjs'))
    for file in fs.listdir(fs.join(path.PROJECT_ROOT,
                                   'targets', 'nuttx-stm32f4', 'app')):
        fs.copy(fs.join(path.PROJECT_ROOT,'targets','nuttx-stm32f4','app',file),
                fs.join(nuttx_root, 'apps', 'system', 'iotjs'))

    # Step 3
    fs.chdir(fs.join(nuttx_root, 'nuttx', 'tools'))
    ex.check_run_cmd('./configure.sh', ['stm32f4discovery/usbnsh'])
    fs.chdir('..')
    fs.copy(fs.join(path.PROJECT_ROOT,
                    'targets',
                    'nuttx-stm32f4',
                    'nuttx',
                    '.config.travis'),
            '.config')


def build_nuttx(nuttx_root, buildtype):
    fs.chdir(fs.join(nuttx_root, 'nuttx'))
    try:
        code = 0
        if buildtype == "release":
            code = ex.run_cmd('make',
                              ['IOTJS_ROOT_DIR=' + path.PROJECT_ROOT, 'R=1'])
        else:
            code = ex.run_cmd('make',
                              ['IOTJS_ROOT_DIR=' + path.PROJECT_ROOT, 'R=0'])

        if code == 0:
            return True
        else:
            print('Failed to build nuttx')
            return False
    except OSError as err:
        print('Failed to build nuttx: %s' % err)
        return False

def setup_tizen_root(tizen_root):
    if fs.exists(tizen_root):
        fs.chdir(tizen_root)
        ex.check_run_cmd('git', ['pull'])
        fs.chdir(path.PROJECT_ROOT)
    else:
        ex.check_run_cmd('git', ['clone',
            'https://github.com/pmarcinkiew/tizen3.0_rootstrap.git',
            tizen_root])


def build(buildtype, args=[]):
    fs.chdir(path.PROJECT_ROOT)
    ex.check_run_cmd('./tools/build.py', ['--buildtype=' + buildtype] + args)


option = parse_option()
config = get_config()
if len(config['module']['exclude']) > 0 :
    include_module = ','.join(config['module']['exclude'])
    include_module = ['--iotjs-include-module=' + include_module]
else:
    include_module = []

build_args = []

if option.buildoptions:
    build_args.extend(option.buildoptions.split(','))

for test in option.test:
    if test == "host":
        for buildtype in option.buildtype:
            build(buildtype, include_module + build_args)

    elif test == "rpi2":
        for buildtype in option.buildtype:
            build(buildtype, ['--target-arch=arm', '--target-board=rpi2']
                              + include_module + build_args)

    elif test == "artik10":
        for buildtype in option.buildtype:
            tizen_root = fs.join(path.PROJECT_ROOT, 'deps', 'tizen')
            setup_tizen_root(tizen_root)
            build(buildtype, ['--target-arch=arm',
                              '--target-os=tizen',
                              '--target-board=artik10',
                              '--compile-flag=--sysroot=' + tizen_root
                              ] + include_module + build_args)

    elif test == "nuttx":
        current_dir = os.getcwd()
        for buildtype in option.buildtype:
            nuttx_root=fs.join(path.PROJECT_ROOT, 'deps', 'nuttx')
            setup_nuttx_root(nuttx_root)
            build_nuttx(nuttx_root, buildtype)
            build(buildtype, ['--target-arch=arm',
                              '--target-os=nuttx',
                              '--nuttx-home=' + fs.join(nuttx_root, 'nuttx'),
                              '--target-board=stm32f4dis',
                              '--jerry-heaplimit=78']
                              + include_module + build_args)

            if not build_nuttx(nuttx_root, buildtype):
                ex.fail('nuttx ' + buildtype + ' build failed')
            fs.chdir(current_dir)

    elif test == "misc":

        args = []
        if os.getenv('TRAVIS') != None:
            args = ['--travis']
        ex.check_run_cmd('tools/check_signed_off.sh', args)

        if not check_tidy(path.PROJECT_ROOT):
            ex.fail("Failed tidy check")

        build("debug", build_args)
        build("debug", ['--no-snapshot', '--jerry-lto']
                       + include_module + build_args)

        build("debug", ['--iotjs-minimal-profile'] + build_args)
