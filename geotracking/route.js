ymaps.ready(function(){

    ymaps.route([@startPoint, @finishPoint]).then(
        function (route) {
            var routePath = '';
            var path = route.getPaths().get(0);
            var segments = path.getSegments();
            var separator = ',';
            for (var i = 0; i < segments.length; i++) {
                if (i==0) separator = '';
                routePath = routePath + separator + segments[i].getCoordinates();
            }
            window.location = "route:"+routePath;
        },
            function (error) {
            window.location = "error:"+error.message;
        }
    );

});