using CMake
using CxxWrap
using BinaryProvider

const verbose = "--verbose" in ARGS
const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))

products = Product[
    LibraryProduct(prefix, "libz3", :libz3),
]

bin_prefix = "https://github.com/JuliaBinaryWrappers/z3_jll.jl/releases/download/z3-v4.8.6+0/z3.v4.8.6"
download_info = Dict(
    Linux(:aarch64, :glibc)     => ("$(bin_prefix).aarch64-linux-gnu.tar.gz", "9ac86e83c247cab66b15b84bb830a216fd1cc34b402595cb4f2795ed03494144"),
    Linux(:armv7l, :glibc)      => ("$(bin_prefix).arm-linux-gnueabihf.tar.gz", "8c507dcc5400494ebd3a1d12afb55936e19863653c421131949cacc7e00a9f3b"),
    Linux(:i686, :glibc)        => ("$(bin_prefix).i686-linux-gnu.tar.gz", "3009219837e73f276f139ad9d4f8a73304465fee05c296a4afb9518807cb1ffc"),
    Linux(:x86_64, :glibc)      => ("$(bin_prefix).x86_64-linux-gnu.tar.gz", "6fa1d440635f4f6ff8a7fdcca10b84377a64865eb0d759fd11ec30fedebf0624"),
    Linux(:powerpc64le, :glibc) => ("$(bin_prefix).powerpc64le-linux-gnu.tar.gz", "3f053cf52a33fea45d5fbdd3cd3586658f0c6bd4d5a03a4f50dd2c38fc89a967"),

    Linux(:aarch64, :musl) => ("$(bin_prefix).aarch64-linux-musl.tar.gz", "e443a8447d5f6637212ab83b46de3ed9da1d07844b3672f39614728dc9d6b6a7"),
    Linux(:armv7l, :musl)  => ("$(bin_prefix).arm-linux-musleabihf.tar.gz", "192a110a8a3e433c0f0a6a0bfb75e58d6767860e1fa18ddb4b76cff08c5b3d22"),
    Linux(:i686, :musl)    => ("$(bin_prefix).i686-linux-musl.tar.gz", "33571f98f9a8a8943d8ec1d777c51fea8241f1fd0a08cc988fd2568bdfa27f02"),
    Linux(:x86_64, :musl)  => ("$(bin_prefix).x86_64-linux-musl.tar.gz", "0e41eb46dd87f0b4b89935480ec79757470dcb93e6e6a036fea6a9a850042997"),

    FreeBSD(:x86_64) => ("$(bin_prefix).x86_64-unknown-freebsd11.1.tar.gz", "32e323a913d5207491f1353dfac1b51af247afa95b03d8fee3459cb7f5d7477c"),
    MacOS(:x86_64)   => ("$(bin_prefix).x86_64-apple-darwin14.tar.gz", "7a814f1ecf2bd2ab5bb55ffc7aa93647bf6f5605ca989378b8b1273a136b06fb"),

    Windows(:i686)   => ("$(bin_prefix).i686-w64-mingw32.tar.gz", "d1a8289fcadd11798e4403980a3198065a4924b1c8bf993ed129c1d1b3a313ce"),
    Windows(:x86_64) => ("$(bin_prefix).x86_64-w64-mingw32.tar.gz", "488899c0654838f6e6f6cce38055438df887ed490e83a7032d0586e12707668c")
)

if any(!satisfied(p; verbose=verbose) for p in products)
    try
        # Download and install binaries
        url, tarball_hash = choose_download(download_info)
        install(url, tarball_hash; prefix=prefix, force=true, verbose=true)
    catch e
        if typeof(e) <: ArgumentError
            error("Your platform $(Sys.MACHINE) is not supported by this package!")
        else
            rethrow(e)
        end
    end
end

z3jl_product = LibraryProduct(prefix, "libz3jl", :libz3jl)

if !satisfied(z3jl_product; verbose=verbose)
    cd(joinpath(@__DIR__, "src"))

    Z3_CXX_INCLUDE_DIRS = joinpath(prefix.path, "include")
    Z3_LIBRARIES = locate(products[1])

    JlCxx_dir = joinpath(dirname(dirname(CxxWrap.jlcxx_path)), "lib", "cmake", "JlCxx")
    CMAKE_FLAGS = `-DCMAKE_BUILD_TYPE=Release -DCMAKE_LIBRARY_OUTPUT_DIRECTORY=$(joinpath(prefix.path, "lib")) -DCMAKE_RUNTIME_OUTPUT_DIRECTORY=$(joinpath(prefix.path, "bin"))`
    run(`$cmake -G "Unix Makefiles" $CMAKE_FLAGS -DJlCxx_DIR=$JlCxx_dir -DZ3_CXX_INCLUDE_DIRS=$Z3_CXX_INCLUDE_DIRS -DZ3_LIBRARIES=$Z3_LIBRARIES -DJulia_PREFIX=$(dirname(Sys.BINDIR))`)
    run(`make`)

    write_deps_file(joinpath(@__DIR__, "deps.jl"), [z3jl_product])
end