$(document).ready(function() {

    $('button').attr('disabled', false);

    var drawing = false;
    var mouseX = 0;
    var mouseY = 0;
    var canvas = $("#surface");
    var canvas_offset = canvas.offset();
    var context = canvas[0].getContext('2d');

    context.lineWidth = 10;

    // Initialize the canvas
    (function initialize() {
        var data = context.createImageData(canvas.width(), canvas.height());
        for (x = 0; x < data.width * data.height; x++) {
            data.data[x * 4 + 0] = 255;
            data.data[x * 4 + 1] = 255;
            data.data[x * 4 + 2] = 255;
            data.data[x * 4 + 3] = 255;
        }
        context.putImageData(data, 0, 0);
    })();

    canvas.mousedown(function(e) {
        mouseX = e.pageX - canvas_offset.left;
        mouseY = e.pageY - canvas_offset.top;
        drawing = true
    });

    canvas.mousemove(function(e) {
        if (!drawing) { return; }

        var startX = mouseX;
        var startY = mouseY;
        var endX = e.pageX - canvas_offset.left;
        var endY = e.pageY - canvas_offset.top;
        mouseX = endX;
        mouseY = endY;

        context.beginPath();
        context.moveTo(startX, startY);
        context.lineTo(endX, endY);
        context.stroke();
    });

    canvas.mouseup(function() {
        drawing = false;
    });

    function podifyImageData(data) {
        var dataArray = [];
        // For simplicity, just extract one channel
        for (x = 0; x < data.width * data.height; x++) {
            dataArray[x] = data.data[x * 4];
        }

        return {
            width: data.width,
            height: data.height,
            data: dataArray
        };
    }

    function blur(backend) {
        $('button').attr('disabled', true);

        var data = context.getImageData(0, 0, canvas.width(), canvas.height());
        var data = podifyImageData(data);
        var data = JSON.stringify(data);
        $.post('/blur/' + backend, data, function(newData) {
            var newData = JSON.parse(newData);
            var data = context.createImageData(canvas.width(), canvas.height());
            for (x = 0; x < data.width * data.height; x++) {
                data.data[x * 4 + 0] = newData.data[x];
                data.data[x * 4 + 1] = newData.data[x];
                data.data[x * 4 + 2] = newData.data[x];
                data.data[x * 4 + 3] = 255;
            }
            context.putImageData(data, 0, 0);

            $('#time').text(newData.time);

            $('button').attr('disabled', false);
        });
    }

    $("#ruby-blur").click(function() {
        blur('ruby');
    });

    $("#rust-blur").click(function() {
        blur('rust');
    });

});
