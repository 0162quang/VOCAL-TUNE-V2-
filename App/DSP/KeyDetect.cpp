// Nhận key bằng chroma (Goertzel trên 36 nốt C3..B5) + hồ sơ Krumhansl-Schmuckler.
#include "VocalDSP.h"
#include <cmath>
#include <vector>

extern "C" int32_t vt_detect_key(const float* x, int32_t n, float sr, float refA4,
                                 int32_t* root, int32_t* isMinor, float* confidence) {
    if (!x || sr < 8000.f) return 0;
    const int dec = sr >= 32000.f ? 2 : 1;
    const float fs = sr / (float)dec;
    const int B = 4096;
    const int m = n / dec;
    if (m < B * 4) return 0;

    std::vector<float> d((size_t)m);
    for (int i = 0; i < m; ++i) {
        float s = 0; for (int k = 0; k < dec; ++k) s += x[i * dec + k];
        d[(size_t)i] = s / (float)dec;
    }
    std::vector<float> win(B), blk(B);
    const float kPi = 3.14159265358979f;
    for (int i = 0; i < B; ++i) win[(size_t)i] = 0.5f - 0.5f * std::cos(2.f * kPi * (float)i / (float)(B - 1));

    float coef[36];
    for (int k = 0; k < 36; ++k) {
        const float f = refA4 * std::pow(2.f, ((float)(48 + k) - 69.f) / 12.f);
        coef[k] = 2.f * std::cos(2.f * kPi * f / fs);
    }
    double chroma[12] = {0};
    for (int s = 0; s + B <= m; s += B) {
        double e = 0;
        for (int i = 0; i < B; ++i) { blk[(size_t)i] = d[(size_t)(s + i)] * win[(size_t)i]; e += (double)d[(size_t)(s + i)] * d[(size_t)(s + i)]; }
        const float rms = (float)std::sqrt(e / B);
        if (rms < 1e-4f) continue;
        for (int k = 0; k < 36; ++k) {
            float s1 = 0, s2 = 0;
            for (int i = 0; i < B; ++i) { const float s0 = blk[(size_t)i] + coef[k] * s1 - s2; s2 = s1; s1 = s0; }
            const float p = s1 * s1 + s2 * s2 - coef[k] * s1 * s2;
            const float mag = std::sqrt(p > 0 ? p : 0.f);
            chroma[(48 + k) % 12] += std::log1p(60.0 * mag / (rms * (float)B * 0.5f + 1e-9f));
        }
    }
    static const double maj[12] = {6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88};
    static const double mnr[12] = {6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17};
    auto corr = [&](const double* prof, int rot) {
        double mc = 0, mp = 0;
        for (int i = 0; i < 12; ++i) { mc += chroma[i]; mp += prof[i]; }
        mc /= 12; mp /= 12;
        double sxy = 0, sxx = 0, syy = 0;
        for (int i = 0; i < 12; ++i) {
            const double a = chroma[(i + rot) % 12] - mc, b = prof[i] - mp;
            sxy += a * b; sxx += a * a; syy += b * b;
        }
        return sxx > 0 && syy > 0 ? sxy / std::sqrt(sxx * syy) : 0.0;
    };
    double best = -2; int br = 0, bm = 0;
    for (int r = 0; r < 12; ++r) {
        const double a = corr(maj, r), b = corr(mnr, r);
        if (a > best) { best = a; br = r; bm = 0; }
        if (b > best) { best = b; br = r; bm = 1; }
    }
    *root = br; *isMinor = bm; *confidence = (float)best;
    return 1;
}
