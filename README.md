A demo of embedding Rust in Ruby.

```
gem install sinatra ffi thin
rustc blur.rs -O
LD_LIBRARY_PATH=. ruby blur.rb
```

Then browse to localhost:4567