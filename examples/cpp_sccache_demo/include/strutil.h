#ifndef CPP_SCCACHE_DEMO_STRUTIL_H
#define CPP_SCCACHE_DEMO_STRUTIL_H

#include <string>
#include <vector>

namespace strutil {

std::string to_upper(const std::string &s);
std::string to_lower(const std::string &s);
std::vector<std::string> split(const std::string &s, char delim);
std::string join(const std::vector<std::string> &parts, const std::string &sep);

}  // namespace strutil

#endif /* CPP_SCCACHE_DEMO_STRUTIL_H */