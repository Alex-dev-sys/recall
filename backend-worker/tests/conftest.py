"""
Pytest configuration for Recall Backend tests
"""

import sys
import os

# Add src to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

import pytest

# Configure pytest-asyncio to use auto mode for async tests
pytest_plugins = ('pytest_asyncio',)
