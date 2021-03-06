package
{

    import com.adobe.serialization.json.JSON;

    import flare.analytics.graph.ShortestPaths;
    import flare.display.DirtySprite;
    import flare.display.LineSprite;
    import flare.display.RectSprite;
    import flare.display.TextSprite;
    import flare.query.methods.update;
    import flare.vis.Visualization;
    import flare.vis.controls.ClickControl;
    import flare.vis.controls.HoverControl;
    import flare.vis.data.Data;
    import flare.vis.data.EdgeSprite;
    import flare.vis.data.NodeSprite;
    import flare.vis.events.SelectionEvent;
    import flare.vis.operator.layout.BundledEdgeRouter;
    import flare.vis.operator.layout.CircleLayout;

    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.filters.DropShadowFilter;
    import flash.geom.Rectangle;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.utils.Dictionary;
    import flash.utils.getDefinitionByName;

    import mx.core.*;
    import mx.formatters.NumberBase;
    import mx.formatters.NumberBaseRoundType;
    import mx.resources.IResourceManager;
    import mx.resources.ResourceManager;

    [SWF(backgroundColor="#ffffff",width="600",height="490",frameRate="30")]
    public class asn_visualization extends Sprite
    {
        private static const VISUALIZATION_BOUNDS:uint=475;

        private static const CIRCLE_LAYOUT:uint=1;

        private static const DEFAULT_DETAIL_TEXT:String="Mouse over a node to see detailed information";
        private static const ON_CLICK_SHOW_PARENTS_AND_CHILDREN:uint=2;

        private static const ON_CLICK_SHOW_PATH_TO_REST_OF_THE_WORLD:uint=1;
        private static const RADIAL_LAYOUT:uint=2;

        private static const clean_up_organization_name:Boolean=false;

        public function asn_visualization()
        {
            initFlexFrameworkSpecifics();
            // create progress bar
            addChild(_bar=new ProgressBar());
            _bar.bar.filters=[new DropShadowFilter(1)];

            var print_mode_setting:int=root.loaderInfo.parameters.print_mode;

            if (print_mode_setting)
            {
                _printing_mode=print_mode_setting;
            }
            else
            {
                _printing_mode=_printing_mode_default_setting;
            }


            // load data file
            var ldr:URLLoader=new URLLoader(new URLRequest(get_json_url()));
            _bar.loadURL(ldr, function():void
                {
                    var json:Object=JSON.decode(ldr.data)

                    var data:Data=buildData(json);
                    visualize(data);
                    _bar=null;
                    update();
                    //this.renderDirty();
                    layout();
                });
        }

        private function initFlexFrameworkSpecifics():void
        {
            Singleton.registerClass("mx.resources::IResourceManager", Class(getDefinitionByName("mx.resources::ResourceManagerImpl")));
            var resourceManager:IResourceManager=ResourceManager.getInstance();
        }


        private var _bar:ProgressBar;

        private var _clicked_node_color:uint=0XFF0000FF;
        private var _default_edge_line_color:uint=0XFFCCCCCC;
        private var _default_node_fill_color:uint=0XFFCCCCCC;
        private var _default_node_line_color:uint=0XFF000000;
        private var _node_point_of_control_line_color:uint=0XFFFF0000;
        private var _node_point_of_control_fill_color:uint=0XFFFF0000;

        private var _detail:TextSprite;



        private var _edges_toogle:TextSprite;
        private var _edges_toogle_container:Sprite
        private var _layout_format_toggle_container:Sprite;
        private var _node_click_behavior_toggle:TextSprite;

        private var _below_vis:TextSprite;
        private var _country_info_box:TextSprite;

        private var layout_format:uint=CIRCLE_LAYOUT;

        private var node_click_behavior:uint=ON_CLICK_SHOW_PATH_TO_REST_OF_THE_WORLD;

        private var previously_clicked_node:NodeSprite=null;

        private var rest_of_world_node:NodeSprite=null;
        private var rest_of_world_node_color:uint=0XFF000000;

        private var scale_graph:Boolean=false;

        private static const show_edges:Boolean=true;
        private var vis:Visualization;

        private var country_level_info:Object; // Country stats such as network complexity, PoC, etc.

        private static const _printing_mode_default_setting:Boolean=false; // Set to true to enable hiding instruction so graphs look better printed		
        private static var _printing_mode:Boolean=false;

        private static var _toggle_rect_background:RectSprite;

        private static var _info_text_border_line:LineSprite=null;


        public function visualize(data:Data):void
        {
            vis=new Visualization(data);

            vis.bounds=new Rectangle(0, 0, VISUALIZATION_BOUNDS, VISUALIZATION_BOUNDS);

            restore_edges_color();
            restore_nodes_color();

            vis.controls.add(new HoverControl(NodeSprite,
                // by default, move highlighted items to front
                HoverControl.MOVE_AND_RETURN,
                // highlight node border on mouse over
                function(e:SelectionEvent):void
                {
                    e.node.lineColor=0x88ff00FF;
                },
                // remove highlight on mouse out
                function(e:SelectionEvent):void
                {
                    restore_node_line_color(e.node);
                }));

            vis.controls.add(new ClickControl(NodeSprite, 1, function(evt:SelectionEvent):void
                {
                    evt.node.lineColor=0xFFFF00cc;
                    evt.node.fillColor=0XFF00FF00;

                    restore_edges_color();
                    dim_edges_color();
                    restore_nodes_color();

                    if (previously_clicked_node)
                    {
                        unhighlightNode(previously_clicked_node);
                    }

                    handleClickedNode(evt.node);
                    previously_clicked_node=evt.node;
                }, function(evt:SelectionEvent):void
                {
                    if (previously_clicked_node)
                    {
                        unhighlightNode(previously_clicked_node);
                    }

                    node_click_behavior=ON_CLICK_SHOW_PATH_TO_REST_OF_THE_WORLD;
                    evt.node.lineColor=0xFFFF0Fcc;
                    evt.node.fillColor=0XFF00FF00;
                    unhighlightNode(previously_clicked_node);
                    updateNodeClickBehaviorText(0);
                    restore_edges_color();
                    restore_nodes_color();
                    previously_clicked_node=null;
                    vis.update();
                }));

            create_toggle_rect_background();

            // add mouse-over details
            vis.controls.add(new HoverControl(NodeSprite, HoverControl.MOVE_TO_FRONT, function(evt:SelectionEvent):void
                {
                    _detail.htmlText=get_asn_summary_string(evt.node);
                    layout();
                }, function(evt:SelectionEvent):void
                {
                    _detail.text=word_wrap_to_default(DEFAULT_DETAIL_TEXT);
                }));

            updateOperators(CIRCLE_LAYOUT);

            vis.continuousUpdates=false;
            vis.update();

            addDetail();
            addButtons();

            if (_printing_mode)
            {
                hideInfoForPrinting();
            }

            addChild(vis);
            vis.update();
            layout();
            vis.update();
        }

        private function create_toggle_rect_background():void
        {
            _toggle_rect_background=new RectSprite(0, 0, 600, 30);
            _toggle_rect_background.fillColor=0XFFF1F1F1;
            _toggle_rect_background.lineColor=0XFFF1F1F1;
            _toggle_rect_background.cornerSize=10;
            addChild(_toggle_rect_background);
        }

        private function hideInfoForPrinting():void
        {
            _edges_toogle_container.visible=false;
            _layout_format_toggle_container.visible=false;
            _detail.visible=false;
            _node_click_behavior_toggle.visible=false;
        }


        private function make_TextSprite(sprite_text:String)
        {
            var _ret:TextSprite=new TextSprite(sprite_text, null, TextSprite.DEVICE);
            _ret.font="Helvetica";

            return _ret;
        }

        private function create_toggle_sprite(true_text:String, false_text:String, true_function:Function, false_function:Function, toggle_start:Boolean):Sprite
        {
            var ret:Sprite=new Sprite();
            ret.buttonMode=true;

            var toggle_state:Boolean=toggle_start;

            var _edges_show_text:TextSprite=make_TextSprite(true_text);

            _edges_show_text.name="true_text";

            var _edges_hide_text:TextSprite=make_TextSprite(false_text);

            _edges_hide_text.name="false_text";

            var _edges_slash_text:TextSprite=make_TextSprite("/");

            ret.mouseChildren=false;

            ret.addChild(_edges_show_text);
            ret.addChild(_edges_slash_text);
            ret.addChild(_edges_hide_text);


            _edges_slash_text.x=_edges_show_text.x + _edges_show_text.width;
            _edges_hide_text.x=_edges_slash_text.x + _edges_slash_text.width;

            ret.addEventListener(MouseEvent.CLICK, function(evt:MouseEvent):void
                {
                    toggle_state=!toggle_state;

                    if (toggle_state)
                    {
                        true_function();
                    }
                    else
                    {
                        false_function();
                    }
                    updateEdgeToogleText(ret, toggle_state);
                    vis.update();
                    layout();
                });

            updateEdgeToogleText(ret, toggle_state);
            return ret;
        }

        private function create_edges_toogle():void
        {
            _edges_toogle_container=create_toggle_sprite("SHOW EDGES", "HIDE EDGES", showEdges, hideEdges, show_edges);

            addChild(_edges_toogle_container);
        }

        private function create_layout_format_toogle(layout_format:uint):void
        {
            var layout_is_circle:Boolean=(layout_format == CIRCLE_LAYOUT);
            _layout_format_toggle_container=create_toggle_sprite("CIRCLE LAYOUT", "RADIAL LAYOUT", function():void
                {
                    updateOperators(CIRCLE_LAYOUT)
                }, function():void
                {
                    updateOperators(RADIAL_LAYOUT)
                }, layout_is_circle);

            addChild(_layout_format_toggle_container);
        }

        private function addButtons():void
        {
            create_edges_toogle();
            _node_click_behavior_toggle=make_TextSprite("");
            _node_click_behavior_toggle.textField.multiline=true;
            _node_click_behavior_toggle.buttonMode=false;

            updateNodeClickBehaviorText();
            addChild(_node_click_behavior_toggle);

            create_layout_format_toogle(CIRCLE_LAYOUT);

            _below_vis=make_TextSprite("XXX");
            addChild(_below_vis);

            var number_base:NumberBase=new NumberBase();

            _country_info_box=make_TextSprite("XXX");

            _country_info_box.textField.multiline=true;
            var country_info_string:String=country_info_string="<b>Country Summary:</b>\n";
            country_info_string+="Network Complexity: " + number_base.formatPrecision(country_level_info['complexity'], 3) + "\n";
            country_info_string+=number_base.formatThousands(country_level_info['total_ips']) + " IP Addresses" + "\n";
            country_info_string+=number_base.formatThousands(country_level_info["points_of_control"]) + " Points of Control: " + "\n";
            country_info_string+=number_base.formatThousands(country_level_info["ips_per_points_of_control"]) + " IPs per Point of Control";

            _country_info_box.htmlText=country_info_string;
            // Work around flare bug
            _country_info_box.textFormat=_country_info_box.textFormat;

            addChild(_country_info_box);

        }

        private function addDetail():void
        {
            _detail=make_TextSprite("");
            _detail.textField.multiline=true;
            _detail.htmlText=word_wrap_to_default(DEFAULT_DETAIL_TEXT);
            // Work around flare bug
            _detail.textFormat=_detail.textFormat;
            addChild(_detail);
        }

        private function asn_type_to_string(asn_type:String):String
        {
            var ret:String;

            return ret;
        }

        private function buildData(json:Object):Data
        {
            var data:Data=new Data(true);

            var asn_to_node:Dictionary=new Dictionary();

            var total_ips:int=0;

            var o:Object;

            country_level_info=json.country_level_info;

            var arr:Array=json.asns;
            for each (o in arr)
            {
                var nodeSprite:NodeSprite=data.addNode(o);
                asn_to_node[o['asn']]=nodeSprite;
                var direct_ips:int=o['direct_ips']
                total_ips+=direct_ips;
            }

            var average_ips:int=total_ips / arr.length;

            for each (o in arr)
            {
                var nodeSprite:NodeSprite=asn_to_node[o['asn']];
                var customers:Array=o['customers'];

                var effective_monitorable_ips:int=o['total_monitorable'];
                var direct_ips:int=o['direct_ips'];
                var percentage_monitorable:Number=o['percent_monitorable'];
                var node_size:Number;

                node_size=1 * Math.log(effective_monitorable_ips) / Math.log(average_ips);
                nodeSprite.size=node_size;
                node_size=Math.log(effective_monitorable_ips / average_ips);
                node_size/=Math.LN10;
                node_size=Math.max(node_size, 0.3);

                node_size=percentage_monitorable

                node_size/=10;
                node_size=Math.max(node_size, 0.3);
                nodeSprite.size=node_size;

                if (nodeSprite == null)
                    throw new Error("nodeSprite cannot be null");


                if (o['asn'] == 'REST_OF_WORLD')
                {
                    rest_of_world_node=nodeSprite;
                    nodeSprite.size=2;
                    rest_of_world_node=nodeSprite;
                    nodeSprite.radius=1000;
                    nodeSprite.angle=0;
                }

                for each (var customer:String in customers)
                {
                    if (asn_to_node[customer])
                    {
                        var customer_node:NodeSprite=asn_to_node[customer];

                        if (customer_node.data['asn'] != 'REST_OF_WORLD')
                        {
                            data.addEdgeFor(customer_node, nodeSprite, true);
                        }
                    }
                }
            }
            return data;
        }

        private function dim_edges_color():void
        {
            for each (var _edge:EdgeSprite in vis.data.edges)
            {
                //Update the alpha channle to lineColor
                var dimmed_color:uint;
                var new_alpha_value:uint=0X44000000;
                dimmed_color=_edge.lineColor;
                dimmed_color&=0X00FFFFFF;
                dimmed_color|=new_alpha_value;
                _edge.lineColor=dimmed_color;
            }
        }

        private function dirty_nodes():void
        {
            for each (var _node:NodeSprite in vis.data.nodes)
            {
                _node.dirty();
            }

            DirtySprite.renderDirty();
        }

        //The flare library should really have this API
        private function findEdgeBetweenNodes(source_node:NodeSprite, dest_node:NodeSprite):EdgeSprite
        {
            var ret:EdgeSprite=null;

            source_node.visitEdges(function(e:EdgeSprite):void
                {
                    if ((e.source == source_node) && (e.target == dest_node))
                    {
                        ret=e;
                    }
                }, NodeSprite.OUT_LINKS);

            return ret;

            source_node.getOutEdge(1);
        }

        private function word_wrap(string:String, line_width:int):String
        {
            var substrings:Array=string.split(/\s+/);
            var ret:String="";

            var line_length:int=0;
            for each (var substring:String in substrings)
            {
                var substring_length:int=substring.length;

                if (substring_length == 0)
                {
                    continue;
                }

                if (ret != "")
                {
                    if ((line_length + substring_length) > line_width)
                    {
                        ret+='\n ';
                        line_length=1;
                    }
                    else
                    {
                        ret+=' ';
                        line_length+=1;
                    }
                }

                // Break on '-' if it's larger than 20 characters.
                if ((substring_length > line_width) && (substring.search(/-/) != -1))
                {
                    substring=substring.split(/-/).join("-\n ");
                    substring_length=substring.split(/-/).pop().toString().length + 1;
                }

                ret+=substring;
                line_length+=substring_length;
            }

            return ret;
        }

        private function word_wrap_to_default(string:String):String
        {
            const line_length_limit:int=15;
            var ret:String=word_wrap(string, line_length_limit);
            return ret;
        }

        private function get_asn_summary_string(node:NodeSprite):String
        {
            var ret:String="";

            var data:Object=node.data;

            if (node == rest_of_world_node)
            {
                ret="This node represents the wider Internet outside the country.";
                ret=word_wrap_to_default(ret);
                return ret;
            }

            var number_base:NumberBase=new NumberBase();

            var asn_name:String=data.organization_name;

            if (clean_up_organization_name)
            {
                //Strip out beginning id from organization name if necessary
                asn_name=asn_name.replace(/^[A-Z]*-AS /, '');
                if (asn_name == data.organization_name)
                {
                    asn_name=asn_name.replace(/^([A-Z-])* /, '');
                }

                /*asn_name = asn_name.replace(/\s+/gm, " ");
                   var pattern:RegExp = /(.{1,25}\S)\s+/g;
                   asn_name = asn_name.replace(pattern, "|$&|$1|\n");
                 */
            }

            asn_name=word_wrap_to_default(asn_name);
            ret+="<b>";
            ret+=asn_name;

            /* Uncomment to show the full organziation_name for debugging
               if (asn_name != data.organization_name)
               {
               ret += "\n ( " + data.organization_name + " ) \n";
               }
             */

            ret+="\n (AS " + data.asn + "#)"
            ret+="</b>";
            ret+="\n";
            ret+="\n" + "Parent of " + number_base.formatRoundingWithPrecision(data.percent_monitorable, NumberBaseRoundType.UP, 3) + "%" + "\n of country IPs";
            ret+="\n";
            ret+="\n" + number_base.formatThousands(number_base.formatRounding(data.total_monitorable, NumberBaseRoundType.UP)) + " child Ips"
            ret+="\n" + number_base.formatThousands(data.direct_ips) + " direct ips";

            ret+="\n" + number_base.formatThousands(node.outDegree + "");
            if (node.outDegree == 1)
            {
                ret+=" parent";

            }
            else
            {
                ret+=" parents";
            }

            ret+="\n" + number_base.formatThousands(node.inDegree + "");

            if (node.inDegree == 1)
            {
                ret+=" child";
            }
            else
            {
                ret+=" children ";
            }

            //ret += "\n Sprite_size: " + node.size;

            /*
               if (data.is_point_of_control)
               {
               ret += "\n Point of Control";
               }
             */

            return ret;
        }

        private function get_json_url():String
        {
            var json_url:String=root.loaderInfo.parameters.json_url;

            if (json_url == null)
            {
                json_url="http://localhost/asn_web_graphs/country_json_summary.php/?cc=CN";
            }

            return json_url;
        }

        private function handleClickedNode(clicked_node:NodeSprite):void
        {
            restore_edges_color();
            dim_edges_color();
            restore_nodes_color();

            if (previously_clicked_node != clicked_node)
            {
                highlightShortestPath(clicked_node);
                node_click_behavior=ON_CLICK_SHOW_PATH_TO_REST_OF_THE_WORLD;
                updateNodeClickBehaviorText(1);
            }
            else if (node_click_behavior == ON_CLICK_SHOW_PATH_TO_REST_OF_THE_WORLD)
            {
                highlightNode(clicked_node);
                node_click_behavior=ON_CLICK_SHOW_PARENTS_AND_CHILDREN;
                updateNodeClickBehaviorText(2);
            }
            else
            {
                highlightShortestPath(clicked_node);
                node_click_behavior=ON_CLICK_SHOW_PATH_TO_REST_OF_THE_WORLD
                updateNodeClickBehaviorText(1);
            }

            vis.update();
            update();

            clicked_node.fillColor=_clicked_node_color;
            rest_of_world_node.fillColor=rest_of_world_node_color;
            vis.update();
            layout();
        }


        private function hideEdges():void
        {
            for each (var _edge:EdgeSprite in vis.data.edges)
            {
                _edge.visible=false;

            }

            vis.update();
        }


        private function highlight_immediate_connections(node:NodeSprite, edges_visted:uint, alpha:uint, color:uint):void
        {
            node.visitEdges(function(e:EdgeSprite):void
                {
                    e.alpha=0.5;
                    e.lineColor=color;
                    e.lineColor&=alpha;
                }, edges_visted);

            node.visitNodes(function(n:NodeSprite):void
                {
                    n.fillColor=color;
                    n.fillColor&=alpha;
                    if (n.fillColor != color)
                    {
                        trace("FillColor: " + n.fillColor + " Expected color = " + color);
                    }
                }, edges_visted);
        }

        private function highlight_recursively(node:NodeSprite, edges_visted:uint, alpha:uint, color:uint):void
        {
            if (node.data.hightlighted)
                return;

            node.data.highlighted=true;

            highlight_immediate_connections(node, edges_visted, alpha, color);

            alpha&=0X55FFFFFF;
            node.visitNodes(function(n:NodeSprite):void
                {
                    highlight_recursively(n, edges_visted, alpha, color);
                }, edges_visted);
        }

        private function highlightNode(node:NodeSprite, alpha:uint=0XFFFFFFFF):void
        {
            highlight_recursively(node, NodeSprite.IN_LINKS, alpha, 0xff00ff00);
            highlight_recursively(node, NodeSprite.OUT_LINKS, alpha, 0xffff0000);

            vis.update();
        }

        private function highlightShortestPath(node:NodeSprite):void
        {
            var sp:ShortestPaths=new ShortestPaths();
            sp.calculate(vis.data, node);
            var sp_shortest_to:Array=sp.getShortestPathTo(rest_of_world_node);

            var prev_node:NodeSprite;

            var x:int;
            if (node.data['asn'] == '21341')
            {
                x++;
                x--;
            }

            for each (var child_node:NodeSprite in sp_shortest_to)
            {

                if (child_node != node)
                {
                    var e:EdgeSprite=findEdgeBetweenNodes(prev_node, child_node);
                    e.lineColor=0xff00ff00;
                    child_node.fillColor=0xff00ff00;
                }
                prev_node=child_node;
            }

            rest_of_world_node.fillColor=rest_of_world_node_color;
        }

        private function layout():void
        {
            if (vis)
            {
                vis.update();
            }

            var button_y_pos:int=10;

            if (_edges_toogle_container)
            {
                _edges_toogle_container.y=button_y_pos;
                _edges_toogle_container.x=3;
            }

            if (_layout_format_toggle_container)
            {
                _layout_format_toggle_container.y=_edges_toogle_container.y;
                _layout_format_toggle_container.x=_edges_toogle_container.x + _edges_toogle_container.width + 15;
            }

            var vis_y_pos:int=_layout_format_toggle_container.y + 10;
            vis.update();

            if (_detail)
            {
                _detail.x=vis.bounds.width + 1;
                _detail.y=vis.bounds.y + vis.bounds.height / 8;
            }

            if (_node_click_behavior_toggle)
            {
                _node_click_behavior_toggle.y=_detail.y + _detail.height + 10;
                _node_click_behavior_toggle.x=_detail.x;
            }

            vis.y=vis_y_pos;

            _below_vis.text="";
            _below_vis.text+="vis bounds  " + vis.bounds;
            _below_vis.text+=" vis.x " + vis.x;
            _below_vis.text+=" vis.y " + vis.y;
            _below_vis.y=vis.y + vis.bounds.height - 10;
            _below_vis.x=vis.y + vis.bounds.width / 2;
            _below_vis.text+="under vis " + _below_vis.y

            _below_vis.visible=false;

            if (_country_info_box)
            {
                // We need to hard position values because we can't get accurate values for the size of the text.
                _country_info_box.x=vis.x + vis.bounds.width - 70;
                //_country_info_box.horizontalAnchor = TextSprite.LEFT;
                // _country_info_box.verticalAnchor   = TextSprite.TOP;
                _country_info_box.y=vis.y + vis.height - _country_info_box.height + 5;
            }

            if (!_info_text_border_line)
            {
                //TODO it would be better to create this sprite earlier and then move it.
                //Unfortunately moving the Sprite doesn't seem to work 
                // Since the Sprite's location must be relative to other sprites, we have to wait
                // until everything else is in place 
                _info_text_border_line=new LineSprite();

                _info_text_border_line.x1=_detail.x - 10;
                _info_text_border_line.x2=_detail.x - 10;
                _info_text_border_line.y1=_detail.y - 2;
                _info_text_border_line.y2=_country_info_box.y - 20;

                addChild(_info_text_border_line);
            }
        }

        private function restore_edges_color():void
        {
            for each (var _edge:EdgeSprite in vis.data.edges)
            {
                _edge.lineColor=_default_edge_line_color;
                _edge.mouseEnabled=false;
            }

            dim_edges_color();
        }

        private function isPointOfControl(node:NodeSprite):Boolean
        {
            return node.data.is_point_of_control;
        }

        private function restore_node_line_color(node:NodeSprite):void
        {
            if (isPointOfControl(node))
            {
                node.lineColor=_node_point_of_control_line_color;
            }
            else
            {
                node.lineColor=_default_node_line_color;
            }
        }

        private function restore_node_fill_color(node:NodeSprite)
        {
            if (isPointOfControl(node))
            {
                node.fillColor=_node_point_of_control_fill_color;
            }
            else
            {
                node.fillColor=_default_node_fill_color;
            }
        }


        private function restore_nodes_color():void
        {
            for each (var _node:NodeSprite in vis.data.nodes)
            {
                _node.data.highlighted=false;
                restore_node_fill_color(_node);

                restore_node_line_color(_node);

                _node.focusRect=true;
                _node.dirty();
            }

            rest_of_world_node.fillColor=rest_of_world_node_color;
        }

        private function showEdges():void
        {
            for each (var _edge:EdgeSprite in vis.data.edges)
            {
                _edge.visible=true;
            }

            vis.update();
        }

        private function unhighlightNode(node:NodeSprite):void
        {
            node.visitEdges(function(e:EdgeSprite):void
                {
                    e.alpha=0.5;
                    e.lineColor=_default_edge_line_color;
                    vis.marks.setChildIndex(e, vis.marks.numChildren - 1);
                }, NodeSprite.IN_LINKS);

            // highlight links the focus depends on in red
            node.visitEdges(function(e:EdgeSprite):void
                {
                    e.alpha=0.5;
                    e.lineColor=_default_edge_line_color;
                    vis.marks.setChildIndex(e, vis.marks.numChildren - 1);
                }, NodeSprite.OUT_LINKS);

            restore_node_fill_color(node);
            restore_node_line_color(node);

            node.visitNodes(function(n:NodeSprite):void
                {
                    restore_node_fill_color(n);
                });

            vis.update();
        }

        private function updateEdgeToogleText(toggle_sprite:Sprite, toggle_var:Boolean):void
        {
            var show_text:TextSprite=(TextSprite)(toggle_sprite.getChildByName("true_text"));
            var hide_text:TextSprite=(TextSprite)(toggle_sprite.getChildByName("false_text"));

            if (toggle_var)
            {
                hide_text.color=0XFF0000FF;
                show_text.color=0XFF666666;
            }
            else
            {
                show_text.color=0XFF0000FF;
                hide_text.color=0XFF666666;
            }

            update();
        }

        private function updateNodeClickBehaviorText(node_click_behavior:uint=0):void
        {
            switch (node_click_behavior)
            {
                case 0:
                    _node_click_behavior_toggle.text="Click a node to see its path to the wider Internet";
                    break;

                case 1:
                    _node_click_behavior_toggle.text="Showing node's path to the wider Internet. Click node again to see its parent and child links.";
                    break;
                case 2:
                    _node_click_behavior_toggle.text="Showing node's parent and child links. Click node again to see its path to the wider Internet.";
                    break;
            }

            _node_click_behavior_toggle.text=word_wrap_to_default(_node_click_behavior_toggle.text);
        }

        private function updateOperators(layout_format:uint):void
        {
            vis.operators.clear();

            vis.scaleX=1;
            vis.scaleY=1;

            const CIRCLE_LAYOUT_BOUNDS:int=1000;

            if (layout_format == CIRCLE_LAYOUT)
            {
                var circle_layout:CircleLayout=new CircleLayout(null, null, true);

                if (scale_graph)
                {
                    if (vis.data.nodes.length > 200)
                    {
                        circle_layout.padding=vis.data.nodes.length;
                            //vis.scaleX = 0.5;
                            //vis.scaleY = 0.5;
                    }
                }
                circle_layout.layoutBounds=new Rectangle(0, 0, CIRCLE_LAYOUT_BOUNDS, CIRCLE_LAYOUT_BOUNDS);
                //circle_layout.startRadiusFraction = 1/5;
                vis.operators.add(circle_layout);
                if (scale_graph)
                    vis.operators.add(new ScaleOperator());

                vis.operators.add(new BundledEdgeRouter(0.85));

            }
            else if (layout_format == RADIAL_LAYOUT)
            {
                var circle_layout:CircleLayout=new CircleLayout(null, null, true);
                circle_layout.layoutBounds=new Rectangle(0, 0, CIRCLE_LAYOUT_BOUNDS, CIRCLE_LAYOUT_BOUNDS);
                vis.operators.add(circle_layout);
                CircleLayout(vis.operators.last).startRadiusFraction=3 / 5;
                // bundle edges to route along the tree structure
                vis.operators.add(new BundledEdgeRouter(0.95));
            }

            DirtySprite.renderDirty();

            vis.bounds.x=0;
            vis.bounds.y=0;
            vis.scaleX=VISUALIZATION_BOUNDS / CIRCLE_LAYOUT_BOUNDS;
            vis.scaleY=VISUALIZATION_BOUNDS / CIRCLE_LAYOUT_BOUNDS;
            vis.cacheAsBitmap=true;
        }

    }
}
