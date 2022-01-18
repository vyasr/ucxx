# Copyright (c) 2022, NVIDIA CORPORATION. All rights reserved.
# See file LICENSE for terms.

# distutils: language = c++
# cython: language_level=3

import enum
import functools

from libc.stdint cimport uintptr_t
from libcpp.map cimport map as cpp_map
from libcpp.string cimport string
from libcpp.utility cimport move

from . cimport ucxx_api
from .ucxx_api cimport *


class Feature(enum.Enum):
    TAG = UCP_FEATURE_TAG
    RMA = UCP_FEATURE_RMA
    AMO32 = UCP_FEATURE_AMO32
    AMO64 = UCP_FEATURE_AMO64
    WAKEUP = UCP_FEATURE_WAKEUP
    STREAM = UCP_FEATURE_STREAM
    AM = UCP_FEATURE_AM


cdef class UCXContext():
    """Python representation of `ucp_context_h`

    Parameters
    ----------
    config_dict: Mapping[str, str]
        UCX options such as "MEMTYPE_CACHE=n" and "SEG_SIZE=3M"
    feature_flags: Iterable[Feature]
        Tuple of UCX feature flags
    """
    cdef:
        UCXXContext _context
        dict _config

    def __init__(
        self,
        config_dict={},
        feature_flags=(
            Feature.TAG,
            Feature.WAKEUP,
            Feature.STREAM,
            Feature.AM,
            Feature.RMA
        )
    ):
        cdef cpp_map[string, string] cpp_config
        for k, v in config_dict.items():
            cpp_config[k.encode("utf-8")] = v.encode("utf-8")
        feature_flags = functools.reduce(
            lambda x, y: x | y.value, feature_flags, 0
        )
        self._context = move(UCXXContext(cpp_config, feature_flags))

        cdef dict context_config = self._context.get_config()
        self._config = {k.decode("utf-8"): v.decode("utf-8") for k, v in context_config.items()}

    cpdef dict get_config(self):
        return self._config

    @property
    def handle(self):
        return int(<uintptr_t>self._context.get_handle())

    cpdef str get_info(self):
        return self._context.get_info().decode("utf-8")