New Steamworks SDK
* Unpack in -sdk as eg sdk-1.6
* STEAM_SDK=$(pwd)/new-sdk make redist
* git diff to sanity check & review
* update Makefile SDK version
* make uninstall; make install
* Go back to steamworks, make generate
* git diff to compare and explore, make patches, build etc.
* On happy commit & tag & push -sdk
* Update SDK level in Steamworks Readme
* Commit and push Steamworks
