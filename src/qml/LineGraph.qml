import QtQuick
import Cutie

Item {
	id: root

	property var values: []
	property real maxValue: 1.0 // 1.0 = 100% utilization
	property color lineColor: Atmosphere.textColor
	property real fillOpacity: 0.18
	property int gridLines: 4          // Horizontal grid divisions
	property int verticalGridLines: 10 // Vertical grid divisions

	implicitHeight: 160

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

			// --- Outer Border & Grid Mesh ---
			ctx.strokeStyle = Qt.rgba(root.lineColor.r, root.lineColor.g, root.lineColor.b, 0.15);
			ctx.lineWidth = 1;

			// Horizontal Grid Lines
			for (var g = 0; g <= root.gridLines; g++) {
				var gy = Math.floor((h / root.gridLines) * g);
				ctx.beginPath();
				ctx.moveTo(0, gy);
				ctx.lineTo(w, gy);
				ctx.stroke();
			}

			// Vertical Grid Lines
			for (var v = 0; v <= root.verticalGridLines; v++) {
				var vx = Math.floor((w / root.verticalGridLines) * v);
				ctx.beginPath();
				ctx.moveTo(vx, 0);
				ctx.lineTo(vx, h);
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

			function yFor(val) {
				var norm = Math.max(0, Math.min(1, val / localMax));
				return h - (norm * h);
			}

			// --- Filled Area Under Graph ---
			ctx.beginPath();
			ctx.moveTo(0, h);
			for (var j = 0; j < count; j++)
				ctx.lineTo(j * stepX, yFor(root.values[j]));
			ctx.lineTo((count - 1) * stepX, h);
			ctx.closePath();
			ctx.fillStyle = Qt.rgba(root.lineColor.r, root.lineColor.g, root.lineColor.b, root.fillOpacity);
			ctx.fill();

			// --- Line Chart ---
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
			ctx.lineWidth = 1.5;
			ctx.stroke();
		}
	}
}
