rm -rf build && CXX=clang++ make -j && touch src/b.cppm && CXX=clang++ make -j
rm -rf build && CXX=g++ make -j && touch src/b.cppm && CXX=g++ make -j
rm -rf build && CXX=cl make -j && touch src/b.cppm && CXX=cl make -j
