BLAS Switcher tool for Julia
========
> This is built in 1 night. If one doesn't expect the tool to work, he'll find his computer gracious if it does.

## Motivation
To link Julia to SVE-enabled math library on Post-K. That's it. [BLIS](https://github.com/flame/blis) is just for linking tests, though I like BLIS very much.

## How to Use
~~Read the source code and you'll be able to do it yourself.~~ I referred heavily to [MKL.jl](https://github.com/JuliaComputing/MKL.jl)'s implementation of this, but in a much more spartan way. Generally if you have, say `libblis.so` installed at `/opt/blis/lib`, then for installing it to your Julia distribution, just clone the repository, `cd` to project root and type:

``` Julia
]activate .
using BlaSwitch
set_BLA_to("libblis.so", "/opt/blis/lib")
update_bla()
```

Then it'll somehow work for you. If you feel unsafe about this, I'd like to suggest backuping `[Your Julia Prefix]/share/julia/base/sysimg.jl` and `[Your Julia Prefix]/share/julia/base/build_h.jl`.

## License
I was to license this "installer" under [WTFPL](http://www.wtfpl.net), but it seems conflict with MKL.jl's MIT (*Really*?) or agreement concerning usage of the Post-K (Fugaku) computer. So anyway I'm currently putting my name under it with a [Mozilla Public License](https://www.mozilla.org/en-US/MPL).
