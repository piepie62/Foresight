package pie.Foresight
{
	import Bezel.Bezel;
	import Bezel.Events.EventTypes;
	import Bezel.Events.IngameClickOnSceneEvent;
	import Bezel.Events.IngameKeyDownEvent;
	import Bezel.Events.IngameNewSceneEvent;
	import Bezel.Events.IngameRightClickOnSceneEvent;
	import Bezel.Logger;
	
	import com.giab.common.abstract.SpriteExt;
	import com.giab.common.constants.KeyCode;
	
	import com.giab.games.gcfw.GV;
	import com.giab.games.gcfw.entity.Gem;
	import com.giab.games.gcfw.entity.Lantern;
	import com.giab.games.gcfw.entity.Wall;
	import com.giab.games.gcfw.ingame.IngameCore;
	import com.giab.games.gcfw.mcDyn.McBuildWallHelper;
	import com.giab.games.gcfw.mcDyn.McRange;
	import com.giab.games.gcfw.mcStat.CntIngame;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	
	/**
	 * ...
	 * @author piepie62
	 */
	public class Foresight extends MovieClip
	{
		private var bezel:Bezel;
		private var logger:Logger;
		
		// Game object shortcuts
		private var core:IngameCore;/*IngameCore*/
		private var cnt:CntIngame;/*CntIngame*/
		
		private var g1gem:Gem;
		private var lantern:Lantern;
		
		private var placingType:int;
		
		private var images:Vector.<Vector.<MovieClip>>;
		private var ranges:Vector.<Vector.<McRange>>;
		private var cursorImage:MovieClip;
		private var cursorRange:McRange;
		private var prevGrade:int;
		
		public function Foresight(modLoader:Bezel, gameObjects:Object) 
		{
			this.bezel = modLoader;
			this.logger = modLoader.getLogger("Foresight");
			
			this.core = GV.ingameCore;
			this.cnt = GV.ingameCore.cnt;
			
			this.placingType = -1;
			this.images = new Vector.<Vector.<MovieClip>>();
			this.ranges = new Vector.<Vector.<McRange>>();
			for (var x:int = 0; x < 60; x++)
			{
				this.images[x] = new Vector.<MovieClip>();
				this.ranges[x] = new Vector.<McRange>();
				for (var y:int = 0; y < 38; y++)
				{
					this.ranges[x][y] = new McRange();
					this.ranges[x][y].visible = false;
					this.ranges[x][y].circle.x = x * 28 + 50;
					this.ranges[x][y].circle.y = y * 28 + 4;
					this.ranges[x][y].circle.visible = true;
					this.ranges[x][y].mcMask.width = 1680;
					this.ranges[x][y].mcMask.height = 1064;
					this.ranges[x][y].shrineLine0.visible = false;
					this.ranges[x][y].shrineLine1.visible = false;
					this.ranges[x][y].shrineLine2.visible = false;
					this.ranges[x][y].shrineLine3.visible = false;
					this.ranges[x][y].shrineLine4.visible = false;
					this.ranges[x][y].shrineLine5.visible = false;
					this.ranges[x][y].shrineLine6.visible = false;
					this.ranges[x][y].shrineLine7.visible = false;
					this.ranges[x][y].circleEnh.visible = false;
					
					this.images[x][y] = new MovieClip();
					this.images[x][y].x = x * 28 + 46;
					this.images[x][y].y = y * 28 + 4;
					this.images[x][y].visible = true;
					this.images[x][y].type = -1;
				}
			}
			this.cursorRange = new McRange();
			this.cursorRange.visible = false;
			this.cursorRange.circle.visible = true;
			this.cursorRange.mcMask.width = 1680;
			this.cursorRange.mcMask.height = 1064;
			this.cursorRange.shrineLine0.visible = false;
			this.cursorRange.shrineLine1.visible = false;
			this.cursorRange.shrineLine2.visible = false;
			this.cursorRange.shrineLine3.visible = false;
			this.cursorRange.shrineLine4.visible = false;
			this.cursorRange.shrineLine5.visible = false;
			this.cursorRange.shrineLine6.visible = false;
			this.cursorRange.shrineLine7.visible = false;
			this.cursorRange.circleEnh.visible = false;

			this.cursorImage = new MovieClip();
			this.cursorImage.visible = false;
			
			installEventHooks();
			
			logger.log("bind", "Foresight loaded");
		}
		
		public function installEventHooks(): void
		{
			bezel.addEventListener(EventTypes.INGAME_CLICK_ON_SCENE, clickOnSceneHook);
			bezel.addEventListener(EventTypes.INGAME_RIGHT_CLICK_ON_SCENE, rightClickOnSceneHook);
			bezel.addEventListener(EventTypes.INGAME_KEY_DOWN, keyDownHook);
			bezel.addEventListener(EventTypes.INGAME_NEW_SCENE, sceneLoadHook);
			GV.main.addEventListener("enterFrame", frameHook);
		}
		
		public function unload(): void
		{
			bezel.removeEventListener(EventTypes.INGAME_CLICK_ON_SCENE, clickOnSceneHook);
			bezel.removeEventListener(EventTypes.INGAME_RIGHT_CLICK_ON_SCENE, rightClickOnSceneHook);
			bezel.removeEventListener(EventTypes.INGAME_KEY_DOWN, keyDownHook);
			bezel.removeEventListener(EventTypes.INGAME_NEW_SCENE, sceneLoadHook);
			GV.main.addEventListener("enterFrame", frameHook);
			
			var hud:SpriteExt = core.cnt.cntRetinaHud;
			for (var x:int = 0; x < 60; x++)
			{
				for (var y:int = 0; y < 38; y++)
				{
					if (hud.contains(images[x][y]))
					{
						hud.removeChild(images[x][y]);
					}
				}
			}
			if (hud.contains(cursorImage))
			{
				hud.removeChild(cursorImage);
			}
		}
		
		public function clickOnSceneHook(e:IngameClickOnSceneEvent): void
		{
			var event:MouseEvent = e.eventArgs.event;
			if (placingType != -1)
			{
				var x:int = buildX(GV.main.mouseX);
				var y:int = buildY(GV.main.mouseY);
				
				if (x >= 0 && y >= 0)
				{
					images[x][y].removeChildren();
					var img:DisplayObject = createImageFor(placingType);
					img.visible = true;
					images[x][y].addChild(img);
					images[x][y].type = placingType;
					setRangeFor(ranges[x][y], x, y, placingType);
					logger.log("setRangeFor", "Radius " + ranges[x][y].circle.height / 2);
					ranges[x][y].visible = true;
				}
				else
				{
					placingType = -1;
				}
				e.eventArgs.continueDefault = false;
			}
		}
		
		public function rightClickOnSceneHook(e:IngameRightClickOnSceneEvent): void
		{
			if (placingType != -1)
			{
				cursorImage.removeChildren();
				cursorRange.visible = false;
				cursorImage.visible = false;
				core.cnt.cntRetinaHud.removeChild(core.cnt.bmpTowerPlaceAvailMap);
				core.cnt.cntRetinaHud.removeChild(core.cnt.bmpNoPlaceBeaconAvailMap);
				placingType = -1;
			}
			else
			{
				var x:int = buildX(GV.main.mouseX);
				var y:int = buildY(GV.main.mouseY);
				for each (var xMod:int in [ -1, 0])
				{
					for each (var yMod:int in [ -1, 0])
					{
						// If it's valid and not a wall, or a wall and in the same tile
						if ((xMod == 0 && yMod == 0) ||
							(x + xMod >= 0 && x + xMod < 60 && y + yMod >= 0 && y + yMod < 38
							 && images[x + xMod][y + yMod].numChildren != 0 &&
							 !(images[x + xMod][y + yMod].getChildAt(0) is McBuildWallHelper)))
						{
							images[x + xMod][y + yMod].removeChildren();
							ranges[x + xMod][y + yMod].visible = false;
						}
					}
				}
			}
		}
		
		public function keyDownHook(e:IngameKeyDownEvent): void
		{
			var event:KeyboardEvent = e.eventArgs.event;
			var type:int = typeFromKeycode(event.keyCode);
			if (event.ctrlKey)
			{
				if (type != -1 && placingType != type && shouldMakeGhost(type))
				{
					cursorImage.removeChildren();
					e.eventArgs.continueDefault = false;
					this.placingType = type;
					cursorImage.addChild(createImageFor(placingType));
					cursorImage.visible = true;
					cursorRange.visible = true;
					core.cnt.cntRetinaHud.addChild(cursorRange);
					core.cnt.cntRetinaHud.addChild(core.cnt.bmpTowerPlaceAvailMap);
					core.cnt.cntRetinaHud.addChild(core.cnt.bmpNoPlaceBeaconAvailMap);
				}
				else if (type != -1 && placingType == type)
				{
					e.eventArgs.continueDefault = false;
					cursorImage.removeChildren();
					cursorRange.visible = false;
					cursorImage.visible = false;
					this.placingType = -1;
					core.cnt.cntRetinaHud.removeChild(core.cnt.bmpTowerPlaceAvailMap);
					core.cnt.cntRetinaHud.removeChild(core.cnt.bmpNoPlaceBeaconAvailMap);
				}
			}
			else
			{
				if (type != -1 && placingType != -1)
				{
					e.eventArgs.continueDefault = false;
				}
			}
		}
		
		public function frameHook(event:Event): void
		{
			var hud:SpriteExt = core.cnt.cntRetinaHud;
			var x:int, y:int;
			
			if (this.prevGrade != core.gemGradeToCreate)
			{
				this.prevGrade = isNaN(core.gemGradeToCreate) ? 1 : core.gemGradeToCreate;
				g1gem = GV.ingameCreator.createGem(this.prevGrade, 0, false, false);
				
				for (x = 0; x < 60; x++)
				{
					for (y = 0; y < 38; y++)
					{
						setRangeFor(this.ranges[x][y], x, y, this.images[x][y].type);
					}
				}
			}
				
			x = buildX(GV.main.mouseX);
			y = buildY(GV.main.mouseY);
			
			setRangeFor(cursorRange, x, y, placingType);
			cursorImage.x = x * 28 + 46;
			cursorImage.y = y * 28 + 4;

			for (x = 0; x < 60; x++)
			{
				for (y = 0; y < 38; y++)
				{
					if (core.buildingAreaMatrix != null && core.buildingAreaMatrix[y] != null && core.buildingAreaMatrix[y][x] != null)
					{
						if (core.buildingAreaMatrix[y][x] is Wall)
						{
							if (this.images[x][y].numChildren > 0 && this.images[x][y].getChildAt(0) is McBuildWallHelper)
							{
								this.images[x][y].removeChildren();
								this.ranges[x][y].visible = false;
							}
						}
						else
						{
							this.images[x][y].removeChildren();
							this.ranges[x][y].visible = false;
						}
					}
				}
			}
		}
		
		public function sceneLoadHook(e:IngameNewSceneEvent): void
		{
			ensureLoadedImages();
			clearImages();
			this.placingType = -1;
			this.prevGrade = 1;
			g1gem = GV.ingameCreator.createGem(this.prevGrade, 0, false, false);
			lantern = new Lantern(0,0);
			g1gem.containingBuilding = lantern;
		}
		
		private function clearImages(): void
		{
			var hud:SpriteExt = core.cnt.cntRetinaHud;

			for (var x:int = 0; x < 60; x++)
			{
				for (var y:int = 0; y < 38; y++)
				{
					images[x][y].removeChildren();
					ranges[x][y].visible = false;
				}
			}
		}
		
		private static function typeFromKeycode(code:uint): int
		{
			switch (code)
			{
				// Tower
				case KeyCode.T:
					return 0;
				// Wall
				case KeyCode.W:
					return 1;
				// Trap
				case KeyCode.R:
					return 2;
				// Lantern
				case KeyCode.L:
					return 3;
				// Amplifier
				case KeyCode.A:
					return 4;
				// Pylons
				case KeyCode.P:
					return 5;
			}
			return -1;
		}
		
		private static function buildX(x:int): int
		{
			var ret:int = x - 50;
			if (ret >= 0 && ret / 28 < 60)
			{
				return Math.floor(ret / 28);
			}
			else
			{
				return -1;
			}
		}
		
		private static function buildY(y:int): int
		{
			var ret:int = y - 8;
			if (ret >= 0 && ret / 28 < 60)
			{
				return Math.floor(ret / 28);
			}
			else
			{
				return -1;
			}
		}
		
		private function createImageFor(type:int): DisplayObject
		{
			switch (type)
			{
				case 0:
					return new Bitmap(core.cnt.bmpBuildHelperTower.bitmapData);
				case 1:
					{
						var mbwh:McBuildWallHelper = new McBuildWallHelper();
						mbwh.gotoAndStop(1);
						mbwh.x = 4;
						mbwh.y = 4;
						return mbwh;
					}
				case 2:
					{
						var bmp:Bitmap = new Bitmap(core.cnt.bmpBuildHelperTrap.bitmapData);
						bmp.x = 8;
						bmp.y = 8;
						return bmp;
					}
				case 3:
					return new Bitmap(core.cnt.bmpBuildHelperLantern.bitmapData);
				case 4:
					return new Bitmap(core.cnt.bmpBuildHelperAmp.bitmapData);
				case 5:
					return new Bitmap(core.cnt.bmpBuildHelperPylon.bitmapData);
			}
			return null;
		}
		
		private function setRangeFor(range:McRange, x:int, y:int, type:int): void
		{
			if (type == -1 || type == 1 || type == 2 || type == 4)
			{
				range.circle.visible = false;
				return;
			}

			range.circle.x = x * 28 + 78;
			range.circle.y = y * 28 + 36;
			range.circle.visible = true;
			
			var radius:Number = 0;
			switch (type)
			{
				case 0:
					g1gem.isInLantern = false;
					g1gem.isInTower = true;
					g1gem.recalculateSds(true);
					radius = g1gem.sd5_EnhancedOrTrapOrLantern.range.g();
					break;
				case 3:
					g1gem.containingBuilding = this.lantern;
					g1gem.isInLantern = true;
					g1gem.isInTower = false;
					g1gem.recalculateSds(true);
					radius = g1gem.containingBuilding.range;
					break;
				case 5:
					radius = 28 * 10 * (1 + GV.ingameCore.skillEffectiveValues[20][0].g());
					break;
			}
			
			range.circle.width = range.circle.height = radius * 2;
		}
		
		private function ensureLoadedImages(): void
		{
			if (!core.cnt.cntRetinaHud.contains(this.images[0][0]))
			{
				for (var x:int = 0; x < 60; x++)
				{
					for (var y:int = 0; y < 38; y++)
					{
						core.cnt.cntRetinaHud.addChild(this.images[x][y]);
						core.cnt.cntRetinaHud.addChild(this.ranges[x][y]);
					}
				}
			}
			
			core.cnt.cntRetinaHud.addChild(cursorImage);
			core.cnt.cntRetinaHud.addChild(cursorRange);
		}
		
		private function shouldMakeGhost(type:int): Boolean
		{
			switch (type)
			{
				// Tower
				case 0:
					return this.core.arrIsSpellBtnVisible[13];
				// Wall
				case 1:
					return this.core.arrIsSpellBtnVisible[12];
				// Trap
				case 2:
					return this.core.arrIsSpellBtnVisible[15];
				// Lantern
				case 3:
					return this.core.arrIsSpellBtnVisible[16];
				// Amplifier
				case 4:
					return this.core.arrIsSpellBtnVisible[14];
				// Pylons
				case 5:
					return this.core.arrIsSpellBtnVisible[17];
			}
			
			return false;
		}
	}
	
}
