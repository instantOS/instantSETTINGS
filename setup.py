from setuptools import setup, find_packages

setup(
    name='instantSETTINGS',
    version='0.1',
    packages=find_packages(),
    include_package_data=True,
    py_modules = [ 'mainsettings' ],

    install_requires=['PyGObject'],

    package_data={
        "instantSETTINGS": ["*.glade", "*.desktop"],
    },

    entry_points='''
        [console_scripts]
        mainsettings=instantSETTINGS.mainsettings:main
    ''',

    # metadata to display on PyPI
    author='Paperbenni',
    description='Simple settings app for instantOS',
    keywords='instantos settings',
    url='https://github.com/instantos/instantWELCOME',
    project_urls={
        'Source Code': 'https://github.com/SCOTT-HAMILTON/instantSETTINGS',
    },
    classifiers=[
        'License :: OSI Approved :: Python Software Foundation License'
    ]
)
