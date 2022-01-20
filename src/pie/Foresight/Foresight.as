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
	import com.giab.games.gcfw.constants.ActionStatus;
	
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

		private var displayedGhosts:Vector.<MovieClip>;
		private var displayedRanges:Vector.<McRange>;
		
		private var cursorImage:MovieClip;
		private var cursorRange:McRange;
		private var prevGrade:int;
		private var buildingsChanged:Boolean;
		
		public function Foresight(modLoader:Bezel, gameObjects:Object) 
		{
			this.bezel = modLoader;
			this.logger = modLoader.getLogger("Foresight");
			
			this.core = GV.ingameCore;
			this.cnt = GV.ingameCore.cnt;
			
			this.placingType = -1;
			this.displayedGhosts = new Vector.<MovieClip>();
			this.displayedRanges = new Vector.<McRange>();
			
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
			
			for each (var ghost:MovieClip in displayedGhosts)
			{
				GV.ingameCore.cnt.cntRetinaHud.removeChild(ghost);
			}
			displayedGhosts.length = 0;
			for each (var range:McRange in displayedRanges)
			{
				GV.ingameCore.cnt.cntRetinaHud.removeChild(range);
			}
			GV.ingameCore.cnt.cntRetinaHud.removeChild(cursorImage);
			GV.ingameCore.cnt.cntRetinaHud.removeChild(cursorRange);
		}
		
		public function clickOnSceneHook(e:IngameClickOnSceneEvent): void
		{
			var event:MouseEvent = e.eventArgs.event;
			var i:int;
			if (placingType != -1)
			{	
				if (e.eventArgs.buildingX >= 0 && e.eventArgs.buildingY >= 0)
				{
					if (this.displayedGhosts.length == 0 || this.displayedGhosts.every(function(g:MovieClip, ...args):Boolean{return g.buildX != e.eventArgs.buildingX || g.buildY != e.eventArgs.buildingY || canPlaceImage(g.type, placingType);}))
					{
						var newGhost:MovieClip = createGhost(e.eventArgs.buildingX, e.eventArgs.buildingY, placingType);
						GV.ingameCore.cnt.cntRetinaHud.addChild(newGhost);
						this.displayedGhosts.push(newGhost);
						
						var newRange:McRange = createRange(placingType);
						setRangeFor(newRange, e.eventArgs.buildingX, e.eventArgs.buildingY, placingType);
						if (newRange != null)
						{
							GV.ingameCore.cnt.cntRetinaHud.addChild(newRange);
						}
						this.displayedRanges.push(newRange);
					}
				}
				else
				{
					placingType = -1;
				}
				e.eventArgs.continueDefault = false;
			}
			else
			{
				if (GV.ingameCore.actionStatus == ActionStatus.CAST_BUILDTOWER_INITIATED || GV.ingameCore.actionStatus == ActionStatus.CAST_BUILDTRAP_INITIATED ||
					GV.ingameCore.actionStatus == ActionStatus.CAST_BUILDAMP_INITIATED || GV.ingameCore.actionStatus == ActionStatus.CAST_BUILDLANTERN_INITIATED ||
					GV.ingameCore.actionStatus == ActionStatus.CAST_BUILDPYLON_INITIATED || GV.ingameCore.actionStatus == ActionStatus.CAST_BUILDWALL_DRAGGING)
				{
					buildingsChanged = true;
				}
			}
		}
		
		public function rightClickOnSceneHook(e:IngameRightClickOnSceneEvent): void
		{
			if (placingType != -1)
			{
				GV.ingameCore.cnt.cntRetinaHud.removeChild(cursorImage);
				GV.ingameCore.cnt.cntRetinaHud.removeChild(cursorRange);
				cursorImage = null;
				cursorRange = null;
				GV.ingameCore.cnt.cntRetinaHud.removeChild(GV.ingameCore.cnt.bmpTowerPlaceAvailMap);
				GV.ingameCore.cnt.cntRetinaHud.removeChild(GV.ingameCore.cnt.bmpNoPlaceBeaconAvailMap);
				placingType = -1;
			}
			else
			{
				var x:int = buildX(GV.main.mouseX);
				var y:int = buildY(GV.main.mouseY);

				for (var i:int = displayedGhosts.length-1; i >= 0; i--)
				{
					if ((displayedGhosts[i].buildX == x ||
						(displayedGhosts[i].buildX + 1 == x && displayedGhosts[i].type != 1)) &&
						(displayedGhosts[i].buildY == y ||
						(displayedGhosts[i].buildY + 1 == y && displayedGhosts[i].type != 1)))
					{
						GV.ingameCore.cnt.cntRetinaHud.removeChild(displayedGhosts[i]);
						GV.ingameCore.cnt.cntRetinaHud.removeChild(displayedRanges[i]);
						this.displayedGhosts.splice(i,1);
						this.displayedRanges.splice(i,1);
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
					e.eventArgs.continueDefault = false;
					this.placingType = type;

					var x:int = buildX(GV.main.mouseX);
					var y:int = buildY(GV.main.mouseY);
					
					GV.ingameCore.cnt.cntRetinaHud.removeChild(cursorImage);
					GV.ingameCore.cnt.cntRetinaHud.removeChild(cursorRange);
					cursorImage = createGhost(x, y, type);
					cursorRange = createRange(type);
					setRangeFor(cursorRange, x, y, type);
					GV.ingameCore.cnt.cntRetinaHud.addChild(cursorImage);
					if (cursorRange != null)
					{
						GV.ingameCore.cnt.cntRetinaHud.addChild(cursorRange);
					}

					GV.ingameCore.cnt.cntRetinaHud.addChild(GV.ingameCore.cnt.bmpTowerPlaceAvailMap);
					GV.ingameCore.cnt.cntRetinaHud.addChild(GV.ingameCore.cnt.bmpNoPlaceBeaconAvailMap);
				}
				else if (type != -1 && placingType == type)
				{
					e.eventArgs.continueDefault = false;
					this.placingType = -1;

					GV.ingameCore.cnt.cntRetinaHud.removeChild(cursorImage);
					GV.ingameCore.cnt.cntRetinaHud.removeChild(cursorRange);
					cursorImage = null;
					cursorRange = null;

					GV.ingameCore.cnt.cntRetinaHud.removeChild(GV.ingameCore.cnt.bmpTowerPlaceAvailMap);
					GV.ingameCore.cnt.cntRetinaHud.removeChild(GV.ingameCore.cnt.bmpNoPlaceBeaconAvailMap);
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
			if (this.prevGrade != GV.ingameCore.gemGradeToCreate)
			{
				this.prevGrade = isNaN(GV.ingameCore.gemGradeToCreate) ? 1 : GV.ingameCore.gemGradeToCreate;
				g1gem = GV.ingameCreator.createGem(this.prevGrade, 0, false, false);

				for (var i:int = 0; i < displayedGhosts.length; i++)
				{
					setRangeFor(displayedRanges[i], displayedGhosts[i].buildX, displayedGhosts[i].buildY, displayedGhosts[i].type);
				}
			}
				
			var x:int = buildX(GV.main.mouseX);
			var y:int = buildY(GV.main.mouseY);

			if (cursorImage != null)
			{
				setRangeFor(cursorRange, x, y, placingType);
				cursorImage.x = x * 28 + 46;
				cursorImage.y = y * 28 + 4;
			}

			if (buildingsChanged)
			{
				buildingsChanged = false;

				for (i = displayedGhosts.length-1; i >= 0; i--)
				{
					if (core.buildingAreaMatrix != null
						&& core.buildingAreaMatrix[displayedGhosts[i].buildY] != null
						&& core.buildingAreaMatrix[displayedGhosts[i].buildY][displayedGhosts[i].buildX] != null
						&& (displayedGhosts[i].type == 1 || (displayedGhosts[i].type != 1 && !(core.buildingAreaMatrix[displayedGhosts[i].buildY][displayedGhosts[i].buildX] is Wall))))
					{
						GV.ingameCore.cnt.cntRetinaHud.removeChild(displayedGhosts[i]);
						GV.ingameCore.cnt.cntRetinaHud.removeChild(displayedRanges[i]);
						this.displayedGhosts.splice(i,1);
						this.displayedRanges.splice(i,1);
					}
				}
			}
		}
		
		public function sceneLoadHook(e:IngameNewSceneEvent): void
		{
			this.displayedRanges.length = 0;
			this.displayedGhosts.length = 0;
			this.placingType = -1;
			this.prevGrade = 1;
			g1gem = GV.ingameCreator.createGem(this.prevGrade, 0, false, false);
			lantern = new Lantern(0,0);
			g1gem.containingBuilding = lantern;
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
		
		private function createGhost(x:int, y:int, type:int):MovieClip
		{
			var ret:MovieClip = new MovieClip();
			switch (type)
			{
				case 0:
					ret.addChild(new Bitmap(GV.ingameCore.cnt.bmpBuildHelperTower.bitmapData));
					break;
				case 1:
					{
						var mbwh:McBuildWallHelper = new McBuildWallHelper();
						mbwh.gotoAndStop(1);
						mbwh.x = 4;
						mbwh.y = 4;
						ret.addChild(mbwh);
					}
					break;
				case 2:
					{
						var bmp:Bitmap = new Bitmap(GV.ingameCore.cnt.bmpBuildHelperTrap.bitmapData);
						bmp.x = 8;
						bmp.y = 8;
						ret.addChild(bmp);
					}
					break;
				case 3:
					ret.addChild(new Bitmap(GV.ingameCore.cnt.bmpBuildHelperLantern.bitmapData));
					break;
				case 4:
					ret.addChild(new Bitmap(GV.ingameCore.cnt.bmpBuildHelperAmp.bitmapData));
					break;
				case 5:
					ret.addChild(new Bitmap(GV.ingameCore.cnt.bmpBuildHelperPylon.bitmapData));
					break;
				default:
					return null;
			}
			
			ret.x = x * 28 + 46;
			ret.y = y * 28 + 4;
			ret.type = type;
			ret.buildX = x;
			ret.buildY = y;
			return ret;
		}

		private function setRangeFor(range:McRange, x:int, y:int, type:int): void
		{
			if (range == null)
				return;

			range.circle.x = x * 28 + 78;
			range.circle.y = y * 28 + 36;

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
		
		private function shouldMakeGhost(type:int): Boolean
		{
			switch (type)
			{
				// Tower
				case 0:
					return GV.ingameCore.arrIsSpellBtnVisible[13];
				// Wall
				case 1:
					return GV.ingameCore.arrIsSpellBtnVisible[12];
				// Trap
				case 2:
					return GV.ingameCore.arrIsSpellBtnVisible[15];
				// Lantern
				case 3:
					return GV.ingameCore.arrIsSpellBtnVisible[16];
				// Amplifier
				case 4:
					return GV.ingameCore.arrIsSpellBtnVisible[14];
				// Pylons
				case 5:
					return GV.ingameCore.arrIsSpellBtnVisible[17];
			}
			
			return false;
		}

		private function canPlaceImage(origType:int, newType:int):Boolean
		{
			if (origType == newType)
			{
				return false;
			}
			if (origType == 1 || newType == 1)
			{
				return true;
			}
			return false;
		}

		private function createRange(type:int):McRange
		{
			if (type == -1 || type == 1 || type == 2 || type == 4)
			{
				return null;
			}

			var ret:McRange = new McRange();
			ret.circle.x = x * 28 + 50;
			ret.circle.y = y * 28 + 4;
			ret.circle.visible = true;
			ret.mcMask.width = 1680;
			ret.mcMask.height = 1064;
			ret.shrineLine0.visible = false;
			ret.shrineLine1.visible = false;
			ret.shrineLine2.visible = false;
			ret.shrineLine3.visible = false;
			ret.shrineLine4.visible = false;
			ret.shrineLine5.visible = false;
			ret.shrineLine6.visible = false;
			ret.shrineLine7.visible = false;
			ret.circleEnh.visible = false;

			return ret;
		}
	}
	
}
