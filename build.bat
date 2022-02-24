@echo off

jai source/main.jai -no_dce -import_dir ../modules -- %*
