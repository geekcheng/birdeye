package birdeye.vis.interactivity
{
	import birdeye.vis.interactivity.events.InteractivityEvent;
	import birdeye.vis.interfaces.coords.ICoordinates;
	import birdeye.vis.interfaces.interactivity.IInteractiveGeometry;
	import birdeye.vis.interfaces.interactivity.IInteractivityManager;
	
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	
	/**
	 * Event is dispatched when a mouse over is triggered on a specific geometry.
	 */
	[Event(name="geometryMouseOver", type="birdeye.vis.interactivity.events.InteractivityEvent")]
	
	/**
	 * Event is dispatched when a mouse out is triggered on a specific geometry.
	 */
	[Event(name="geometryMouseOut", type="birdeye.vis.interactivity.events.InteractivityEvent")]
	
	/**
	 * Event is dispatched when a mouse click is triggered on a specific geometry.
	 */
	[Event(name="geometryMouseClick", type="birdeye.vis.interactivity.events.InteractivityEvent")]
	
	public class InteractivityManager extends EventDispatcher implements IInteractivityManager
	{
			
		public function InteractivityManager()
		{
			geometries = new Vector.<IInteractiveGeometry>();
			_mousedOverGeometries = new Vector.<IInteractiveGeometry>();
		}

		protected var geometries:Vector.<IInteractiveGeometry>;
		
		public function registerGeometry(geom:IInteractiveGeometry):void
		{
			if (geometries.indexOf(geom) < 0)
			{
				geometries.push(geom);
			}
		}
		
		public function unregisterGeometry(geom:IInteractiveGeometry):void
		{	
			var i:int = geometries.indexOf(geom);
			
			if (i >= 0)
			{
				geometries.splice(i, 1);
			}
				
		}
		
		protected var _coords:ICoordinates;
		
		public function registerCoordinates(coords:ICoordinates):void
		{
			if (_coords && _coords.elementsContainer)
			{
				_coords.elementsContainer.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
				_coords.elementsContainer.removeEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			}
			
			_coords = coords;
			
			if (_coords && _coords.elementsContainer)
			{
				_coords.elementsContainer.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);	
				_coords.elementsContainer.addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			}
		}
		
		protected var _mousedOverGeometries:Vector.<IInteractiveGeometry>
		
				
		public function mouseMove(event:MouseEvent):void
		{
			var p:Point = new Point(event.localX, event.localY);
	
			var length:int = geometries.length;
		
			// lenght outside of for loop and i++ in second part of for loop is for performance ...
			for (var i:int=0;i<length;i++)
			{
				if (geometries[i].contains(p))
				{
					if (_mousedOverGeometries.indexOf(geometries[i]) < 0)
					{
						_mousedOverGeometries.push(geometries[i]);
						
						var ev:InteractivityEvent = new InteractivityEvent(InteractivityEvent.GEOMETRY_MOUSE_OVER);
						ev.geometry = geometries[i];
						this.dispatchEvent(ev);
					}
					

				}
				else
				{
					var index:int = _mousedOverGeometries.indexOf(geometries[i]);
					
					if (index >= 0)
					{
						var ev:InteractivityEvent = new InteractivityEvent(InteractivityEvent.GEOMETRY_MOUSE_OUT);
						ev.geometry = _mousedOverGeometries[index];
						
						_mousedOverGeometries.splice(index, 1);
						
						this.dispatchEvent(ev);
					}
				}
			}
		}
		
		public function mouseOut(event:MouseEvent):void
		{
			var geomLength:int = _mousedOverGeometries.length;
			if (geomLength > 0)
			{
				var p:Point = new Point(event.localX, event.localY);
				
				for (var i:int = geomLength - 1;i>=0;i--)
				{
					if (!_mousedOverGeometries[i].contains(p))
					{
						var ev:InteractivityEvent = new InteractivityEvent(InteractivityEvent.GEOMETRY_MOUSE_OUT);
						ev.geometry = _mousedOverGeometries[i];	
						
						this.dispatchEvent(ev);
						
						_mousedOverGeometries.splice(i, 1);
						
					}
				}
			}
		}
		
		
	}
}