#[crate_type = "lib"];

use core::libc::c_uint;

// Some basic logging
macro_rules! rtdebug (
    ($( $arg:expr),+) => ( {
        dumb_println(fmt!( $($arg),+ ));

        fn dumb_println(s: &str) {
            use core::str::as_c_str;
            use core::libc::c_char;

            extern {
                fn printf(s: *c_char);
            }

            do as_c_str(s.to_str() + "\n") |s| {
                unsafe { printf(s); }
            }
        }

    } )
)

// An alternate version with no output, for turning off logging
macro_rules! rtdebug_ (
    ($( $arg:expr),+) => ( { } )
)

fn blur_rust(width: uint, height: uint, data: &[u8]) -> ~[u8] {

    let filter = [[0.011, 0.084, 0.011],
                  [0.084, 0.619, 0.084],
                  [0.011, 0.084, 0.011]];

    let mut newdata = ~[];

    for uint::range(0, height) |y| {
        for uint::range(0, width) |x| {
            let mut new_value = 0.0;
            for uint::range(0, filter.len()) |yy| {
                for uint::range(0, filter.len()) |xx| {
                    let x_sample = x - (filter.len() - 1) / 2 + xx;
                    let y_sample = y - (filter.len() - 1) / 2 + yy;
                    let sample_value = data[width * (y_sample % height) + (x_sample % width)];
                    let sample_value = sample_value as float;
                    let weight = filter[yy][xx];
                    new_value += sample_value * weight;
                }
            }
            newdata.push(new_value as u8);
        }
    }

    return newdata;
}

#[no_mangle]
pub extern fn blur(width: c_uint, height: c_uint, data: *mut u8) {
    let width = width as uint;
    let height = height as uint;

    unsafe {
        do vec::raw::mut_buf_as_slice(data, width * height) |data| {
            let out_data = blur_rust(width, height, data);
            vec::raw::copy_memory(data, out_data, width * height);
        }
    }
}
