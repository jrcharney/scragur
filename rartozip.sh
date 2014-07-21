#!/bin/bash

rarfile=$1

unrar x rarfile.rar
zip -r rarfile.cbz rarfile
rm rarfile/*
rmdir rarfile
