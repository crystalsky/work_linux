#include "strutil.h"

#include <cctype>

namespace strutil {

std::string to_upper(const std::string &s) {
    std::string out = s;
    for (char &c : out) {
        c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
    }
    return out;
}

std::string to_lower(const std::string &s) {
    std::string out = s;
    for (char &c : out) {
        c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    }
    return out;
}

std::vector<std::string> split(const std::string &s, char delim) {
    std::vector<std::string> parts;
    std::string cur;
    for (char c : s) {
        if (c == delim) {
            parts.push_back(cur);
            cur.clear();
        } else {
            cur.push_back(c);
        }
    }
    parts.push_back(cur);
    return parts;
}

std::string join(const std::vector<std::string> &parts, const std::string &sep) {
    std::string out;
    for (size_t i = 0; i < parts.size(); ++i) {
        if (i != 0) {
            out += sep;
        }
        out += parts[i];
    }
    return out;
}

}  // namespace strutil