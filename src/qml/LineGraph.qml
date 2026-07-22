import QtQuick
import Cutie

Item {
	id: root

	property var values: []
	property real maxValue: -1 // -1 = auto-scale to the data
	property color lineColor: Atmosphere.textColor
	property real fillOpacity: 0.18
	property int gridLines: 3

	implicitHeight: 120

	onValuesChanged: canvas.requestPaint()
	onMaxValueChanged: canvas.requestPaint()
	onWidthChanged: canvas.requestPaint()
	onHeightChanged: canvas.requestPaint()

	Canvas {
		id: canvas
		anchors.fill: parent

		Component.onCompleted: requestPaint()

		onPaint: {
			var ctx = getContext("2d");
			ctx.reset();

			var w = width;
			var h = height;

			if (w <= 0 || h <= 0)
				return;

			// Grid
			ctx.strokeStyle = Qt.rgba(root.lineColor.r, root.lineColor.g, root.lineColor.b, 0.12);
			ctx.lineWidth = 1;
			for (var g = 0; g <= root.gridLines; g++) {
				var gy = (h / root.gridLines) * g;
				ctx.beginPath();
				ctx.moveTo(0, gy);
				ctx.lineTo(w, gy);
				ctx.stroke();
			}

			if (!root.values || root.values.length < 2)
				return;

			var count = root.values.length;
			var localMax = root.maxValue;
			if (localMax <= 0) {
				localMax = 0.0001;
				for (var i = 0; i < count; i++)
					localMax = Math.max(localMax, root.values[i]);
			}

			var stepX = w / (count - 1);

			function yFor(v) {
				var norm = Math.max(0, Math.min(1, v / localMax));
				return h - (norm * h);
			}

			// Filled area under the line
			ctx.beginPath();
			ctx.moveTo(0, h);
			for (var j = 0; j < count; j++)
				ctx.lineTo(j * stepX, yFor(root.values[j]));
			ctx.lineTo((count - 1) * stepX, h);
			ctx.closePath();
			ctx.fillStyle = Qt.rgba(root.lineColor.r, root.lineColor.g, root.lineColor.b, root.fillOpacity);
			ctx.fill();

			// Line
			ctx.beginPath();
			for (var k = 0; k < count; k++) {
				var px = k * stepX;
				var py = yFor(root.values[k]);
				if (k === 0)
					ctx.moveTo(px, py);
				else
					ctx.lineTo(px, py);
			}
			ctx.strokeStyle = root.lineColor;
			ctx.lineWidth = 2;
			ctx.stroke();
		}
	}
}
