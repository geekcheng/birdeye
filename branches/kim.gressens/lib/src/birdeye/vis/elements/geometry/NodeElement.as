/*  
 * The MIT License
 *
 * Copyright (c) 2008
 * United Nations Office at Geneva
 * Center for Advanced Visual Analytics
 * http://cava.unog.ch
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
 
package birdeye.vis.elements.geometry {

	import birdeye.vis.VisScene;
	import birdeye.vis.data.DataItemLayout;
	import birdeye.vis.elements.RenderableElement;
	import birdeye.vis.guides.renderers.CircleRenderer;
	import birdeye.vis.guides.renderers.RasterRenderer;
	import birdeye.vis.guides.renderers.TextRenderer;
	import birdeye.vis.interfaces.data.IExportableSVG;
	import birdeye.vis.interfaces.data.IVisualDataID;
	import birdeye.vis.interfaces.elements.IEdgeElement;
	import birdeye.vis.interfaces.elements.IGraphLayoutableElement;
	import birdeye.vis.interfaces.renderers.IBoundedRenderer;
	import birdeye.vis.interfaces.transforms.IGraphLayout;
	import birdeye.vis.scales.*;
	import birdeye.vis.trans.graphs.GraphLayout;
	import birdeye.vis.trans.graphs.visual.IVisualNode;
	
	import com.degrafa.IGeometry;
	import com.degrafa.geometry.Geometry;
	import com.degrafa.paint.SolidFill;
	
	import flash.display.DisplayObject;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.IDataRenderer;

	public class NodeElement extends RenderableElement implements IGraphLayoutableElement {

		public function NodeElement() {
			super();
		}
		
		private var _rootNodeId:String;
		public function set rootNodeId(id:String):void {
			_rootNodeId = id;
			if (graphLayout)
				graphLayout.apply(width, height);
		}
		public function get rootNodeId():String {
			return _rootNodeId;
		}
		
		private var _edgeElement:IEdgeElement;
		public function set edgeElement(val:IEdgeElement):void
		{
			_edgeElement = val;
			invalidatingDisplay();
		}
		public function get edgeElement():IEdgeElement
		{
			return _edgeElement;
		}
		
		private var renderers:Array = [];
		override public function get svgData():String
		{
			_svgData = "";
			for each (var itemDisplayObject:DisplayObject in _itemDisplayObjects)
			{
				if (!itemDisplayObject.visible) continue;
				
				if (itemDisplayObject is DataItemLayout)
				{
					for each (var geom:Geometry in DataItemLayout(itemDisplayObject).geometry)
					{
						if (geom is IExportableSVG)
						{
							var initialPoint:Point = localToContent(new Point(
												itemDisplayObject.x - geom.bounds.width/2, 
												itemDisplayObject.y - geom.bounds.height/2));
							
							_svgData += 
									'\n<svg x="' + initialPoint.x + '" y="' + initialPoint.y + '">' +
									'\n<g x="' + geom.bounds.width/2 + '" y="' + geom.bounds.height/2 + 
									'" style="' +
									'fill:' + ((rgbFill) ? '#' + rgbFill:'none') + 
									';fill-opacity:' + alphaFill + ';' + 
									'stroke:' + ((rgbStroke) ? '#' + rgbStroke:'none') + 
									';stroke-opacity:' + alphaStroke + ';' + ';">\n' + 
									IExportableSVG(geom).svgData +  
									'\n</g>\n' +
									'</svg>\n';
						}

						if (itemDisplayObject is IExportableSVG)
								_svgData += '<svg x="' + String(-localOriginPoint.x) +
											   '" y="' + String(-localOriginPoint.y) + '">' + 
											   IExportableSVG(child).svgData + 
											'</svg>';
					}
				}
			}
			var child:Object;
			var localOriginPoint:Point = localToGlobal(new Point(x, y)); 
			for (var i:uint = 0; i<numChildren; i++)
			{
				child = getChildAt(i);
				if (child is IExportableSVG)
					_svgData += '<svg x="' + String(-localOriginPoint.x) +
								   '" y="' + String(-localOriginPoint.y) + '">' + 
								   IExportableSVG(child).svgData + 
								'</svg>';
			}

			return _svgData;
		}
		
		private var _graphLayout:GraphLayout;

		public function set graphLayout(layout:GraphLayout):void {
			_graphLayout = layout;
		}

		public function get graphLayout():GraphLayout {
			return _graphLayout;
		}

		private var _labelFillColor:int = 0xffffff;

		public function set labelFillColor(color:int):void {
			_labelFillColor = color;
		}

		public function get labelFillColor():int {
			return _labelFillColor;
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			_extendMouseEvents = true;
			draggableItems = true;
		}

		override protected function createGlobalGeometryGroup():void {
			// do nothing: no need to create the global group 
	    }

		public function getItemIndexById(id:Object):int {
			const items:Vector.<Object> = dataItems;
			if (!items) return -1;
			for (var i:int = 0; i < items.length; i++) {
				if (items[i][nodeIdField] == id) return i;
			}
			return -1;
		}

		public function isItemVisible(itemId:Object):Boolean {
			return _graphLayout.isNodeItemVisible(itemId);
		}
		
		public function getItemPosition(itemId:Object):Point {
			return _graphLayout.getNodeItemPosition(itemId);
		}

	    override protected function dragDataItem(e:MouseEvent):void
		{
			if (!(e.target is IVisualDataID)) return;

			var nodeID:String = IVisualDataID(e.target).visualObjectID;
			var vGraph:IGraphLayout = _graphLayout;
			var vNode:IVisualNode = vGraph.getVisualNodeById(nodeID);

			if (vNode)
			{
				super.dragDataItem(e);
trace("ENTER", e.target.toString());
				
		    	vNode.x = e.stageX - offsetX + vNode.width/2;
		    	vNode.y = e.stageY - offsetY + vNode.height/2;
		    	var edges:Array = vNode.node.inEdges;
		    	
		    	if (vGraph.graph.isDirectional)
		    		edges.concat(vNode.node.outEdges);
				vGraph.redrawEdges(edges);
		    	e.updateAfterEvent();
			}
		}
		
		override public function onMouseDoubleClick(e:MouseEvent):void
		{
			if (!(e.target is IVisualDataID)) return;
			
			var nodeID:String = IVisualDataID(e.target).visualObjectID;
			
			var vGraph:IGraphLayout = _graphLayout;
			var vNode:IVisualNode = vGraph.getVisualNodeById(nodeID);
			
			mouseDoubleClickFunction(this, vNode);
			VisScene(visScene).invalidateDisplayList();
		}
		
		protected function createItemRenderer(currentItem:Object, position:Point):DisplayObject
		{
			var obj:DisplayObject;
			if (itemRenderer != null) {
				obj = itemRenderer.newInstance() as DisplayObject;
				if (dataField  &&  obj is IDataRenderer) 
					(obj as IDataRenderer).data = currentItem[dataField];

				addChild(obj as DisplayObject);
				if (sizeRenderer > 0)
					obj.width = obj.height = sizeRenderer;
				else {
					if (rendererWidth > 0) 
						obj.width = rendererWidth ;
					if (rendererHeight > 0) 
						obj.height = rendererHeight;
				}
					
				obj.x = position.x;
				obj.y = position.y;
				
				if (draggableItems)
					obj.addEventListener(MouseEvent.MOUSE_DOWN, super.startDragging);
			}
			return obj;
		}

		protected function createGraphicRenderer(currentItem:Object, position:Point):IGeometry {
			const bounds:Rectangle = new Rectangle(0 - _graphicRendererSize, 0 - _graphicRendererSize, _graphicRendererSize * 2, _graphicRendererSize * 2);
			var renderer:IGeometry;

			if (_source)
				renderer = new RasterRenderer(bounds, _source);
 			else {
 				if (graphicRenderer) {
 					renderer = graphicRenderer.newInstance();
 					if (renderer is IBoundedRenderer) (renderer as IBoundedRenderer).bounds = bounds;
 				} else {
					renderer = new CircleRenderer(bounds);
				}
			}
			renderer.fill = fill;
			renderer.stroke = stroke;
			return renderer;
		}
		
		protected function createLabelRenderer(text:String):IGeometry {
			return new TextRenderer(
							   0, 0 + _graphicRendererSize,
							   text,
							   new SolidFill(labelFillColor),
							   true, false, sizeLabel, fontLabel);
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			
		}
		
		override public function drawElement():void {
			super.drawElement();

			graphLayout.nodeElement = this;
			if (edgeElement)
				graphLayout.edgeElement = edgeElement;
			graphLayout.apply(width, height)

			prepareForItemDisplayObjectsCreation();
			renderers = [];
			
			var dataFields:Array = [];
			if (dimName) dataFields["dimName"] = dimName;

			const items:Vector.<Object> = dataItems;
			if (items) {
				var rendWidth:Number = getRendererWidth(null);
				var rendHeight:Number = getRendererHeight(null);
				items.forEach(function(item:Object, index:int, items:Vector.<Object>):void {
					const itemId:Object = item[nodeIdField];
					if (isItemVisible(itemId)) {
						var position:Point = getItemPosition(itemId);
						
						if (sizeScale && sizeField)
						{
							rendWidth = getRendererWidth(item);
							rendHeight = getRendererHeight(item);
						}
						position = new Point(position.x - rendWidth/2, position.y - rendHeight/2);

						if (position != null) {
							var renderer:Object = {itemRenderer: createItemRenderer(item, position),
													graphicRenderer: [createGraphicRenderer(item, position), 
																	createLabelRenderer(item[dimName])]}
							createItemDisplayObject(
								item, dataFields, position, itemId,
								renderer);
							renderers.push(renderer);
						}
					}
				});
			}
			_invalidatedElementGraphic = false;
		}
	}
}