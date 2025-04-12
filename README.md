# caesar-cipher-asm

Caesar cipher implemented with x86_64 assembly

## Usage
```
./caesar-cipher [rotation amount] [text]
```
Eggsamples:
```
$ ./caesar-cipher 13 hello_world
uryyb_jbeyq
$ ./caesar-cipher 13 uryyb_jbeyq
hello_world
```

## Building
Simply run `make`. You'll need to have nasm installed
