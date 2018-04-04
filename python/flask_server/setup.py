from setuptools import setup,find_packages

setup(
    name='flask_server',
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        'flask',
        'celery',
        'flask-pymongo',
        'requests',
        'pymongo',
        'pytest',
        'pytest-runner<4.0',
    ],
    setup_requires=[
        'pytest-runner<4.0',
    ],
    tests_require=[
        'pytest',
    ],
)
