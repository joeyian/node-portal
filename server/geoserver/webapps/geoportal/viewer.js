var app;

Ext.onReady(function() {

	OpenLayers.Util.onImageLoadError = function(){
		 console.log("error loading tiles");
		 this.src = "https://www.google.com.ph/images/srpr/logo11w.png";
	};

	app = new gxp.Viewer({
		// Upload spatial data
		uploadSpatialData: function(){

			// upload
			var win;
			var form = new gxp.LayerUploadPanel({
				url: '/geoserver/rest',
				width: 350,
				frame: true,
				autoHeight: true,
				bodyStyle: 'padding: 10px 10px 0 10px;',
				labelWidth: 65,
				defaults: {
					anchor: '95%',
					allowBlank: false,
					msgTarget: 'side'
				},
				listeners: {
					uploadcomplete: function(panel, detail) {
					
						var layerNames = [];
						var layers = detail["import"].tasks;
						var item, names = {}, resource, layer;
						for (var i=0, len=layers.length; i<len; ++i) {
							item = layers[i];
							if (item.state === "ERROR") {
								Ext.Msg.alert(item.layer.originalName, item.errorMessage);
								return;
							}
							var ws;
							if (item.target.dataStore) {
								ws = item.target.dataStore.workspace.name;
							} else if (item.target.coverageStore) {
								ws = item.target.coverageStore.workspace.name;
							}
							names[ws + ":" + item.layer.name] = true;
							
							layerNames.push(item.layer.title + ' (ID: ' + item.layer.name + ') ');
							console.log(item);
						}

						var source = app.layerSources.local;
						
						source.store.load({
							params: {"_dc": Math.random()},
							callback: function(records, options, success) {
								
								// select newly added layers
								var newRecords = [];
								var last = 0;
								source.store.each(function(record, index) {
									console.log(record.get("name"), record.get("name") in names, names);
									if (record.get("name") in names) {
										last = index;
										newRecords.push(record);
									}
								});
								
								for(i=0;i<newRecords.length; i++){
									var record = newRecords[i];
									
									var name = record.get('name');
									
									var	layerRecord = source.createLayerRecord({
										name: name,
										source: source.id,
									}, null, this);
									
									layerRecord.data.layer.visibility = true;
									app.mapPanel.layers.add(layerRecord);
								}
							},
							scope: this
						});
								
						win.close();

					
						Ext.Msg.show({
							title: 'Success',
							msg: 'Added new layer' + (len !== 1 ? 's' : '') + ': ' + layerNames.join(', </br>'),
							icon: Ext.Msg.INFO,
							buttons: Ext.Msg.OK
						});
					}
				}
			});
			
			if(!win){
				win = new Ext.Window({
					title: 'Upload spatial data',
					layout:'fit',
					plain: true,
					items: form
				});
			}
			win.show();
		},
		
		// Remove all layers
		removeAllLayers: function(){
		
			var tree = Ext.getCmp('tree');
			for(item in tree.root.childNodes[0].childNodes){
				var child = tree.root.childNodes[0].childNodes[item];
				app.mapPanel.map.removeLayer(child.layer);
			}
		},

		// Load all available layers
		loadAllLayers: function(){
		
			if(app.layerSources.local.lazy){
				app.layerSources.local.store.load({
					callback: function(records, opts, success){
						if(success){
							var source = app.layerSources.local;
							
							for(i=0;i<records.length; i++){
								var record = records[i];
								
								var name = record.get('name');
								
								var	layerRecord = source.createLayerRecord({
									name: name,
									source: source.id,
								}, null, this);
								
								layerRecord.data.layer.visibility = false;
								app.mapPanel.layers.add(layerRecord);
							}
						}
					}
				});
			}
		},
        
		proxy: '/geoserver/rest/proxy?url=',
        portalConfig: {
            //renderTo: document.body,
            layout: 'border',
            width: 650,
            height: 465,
            // by configuring items here, we don't need to configure portalItems
            // and save a wrapping container
            items: [
				{
					id: 'myHeader',
					region: 'north',
					html: '<h1 class="pgp-header">&nbsp;</h1>',
					//html: '<h1 class="pgp-header">Philippine Geoportal System :: Agency Node Portal</h1>',
					autoHeight: true,
					border: false,
					margins: '0 0 5 0',
					listeners: {
						beforeRender: function(){
							//this.html = '<h1 class="pgp-header">Philippinexxx Geoportal System :: Agency Node Portal</h1>';
							header = this;

							Ext.Ajax.request({
								async: false,
								url: 'settings.json',
								success: function(resp, req){
									var settings = Ext.decode(resp.responseText);
									var html = '<img src="img/' + settings.logo + '" class="pgp-logo"><h1 class="pgp-header">' + settings.title + '</h1>';
									header.update(html);
								}
							});
							
						}
					}
				},
				{
					// a TabPanel with the map and a dummy tab
					id: 'centerpanel',
					xtype: 'panel',
					layout: 'fit',
					region: 'center',
					//activeTab: 0, // map needs to be visible on initialization
					border: false,
					items: ['mymap']
				}, 
				{
					// container for the layers
					id: 'west',
					xtype: 'container',
					layout: 'fit',
					region: 'west',
					width: 220,
					split: true
				}
			],
            bbar: {id: 'mybbar'}
        },
        
        // configuration of all tool plugins for this application
        tools: [
			{
				ptype: 'gxp_layermanager',
				outputConfig: {
					id: 'tree',
					border: true,
					tbar: [
						{
							xtype: 'button',
							text: 'Upload spatial data',
							iconCls: 'gxp-icon-addlayers',
							handler: function() {
								app.uploadSpatialData();
							},
							scope: this
						}
					] // we will add buttons to 'tree.bbar' later
				},
				outputTarget: 'west',
				groups: {
					default:  {
						title: 'Available layers'
					},
					background: {
						title: 'Base maps', // can be overridden with baseNodeText
						exclusive: true,
					}
				}
			},
			{
				ptype: 'gxp_zoomtolayerextent',
				actionTarget: ['tree.contextMenu']
			},
			{
				ptype: 'gxp_layerproperties',
				actionTarget: ['tree.contextMenu'] //actionTarget: ['tree.tbar', 'tree.contextMenu']
			}, 
			{
				ptype: 'gxp_styler',
				actionTarget: ['tree.contextMenu']
			},
			{
				ptype: 'gxp_deletelayer',
				actionTarget: ['tree.contextMenu']
			}, 			
			{
				ptype: 'gxp_zoomtoextent',
				actionTarget: 'map.tbar'
			}, 
			{
				ptype: 'gxp_zoom',
				actionTarget: 'map.tbar'
			}, 
			{
				ptype: 'gxp_wmsgetfeatureinfo',
				format: 'grid',
				outputConfig: {
					width: 400,
					height: 200
				},
				actionTarget: 'map.tbar', // this is the default, could be omitted
				toggleGroup: 'layertools'
			}, 
			{
				// shared FeatureManager for feature editing, grid and querying
				ptype: 'gxp_featuremanager',
				id: 'featuremanager',
				maxFeatures: 20
			}, 
			{
				ptype: 'gxp_featureeditor',
				featureManager: 'featuremanager',
				autoLoadFeature: true, // no need to 'check out' features
				outputConfig: {panIn: false},
				toggleGroup: 'layertools'
			}
		],
        
        // layer sources
        defaultSourceType: 'gxp_wmssource',
        sources: {
            local: {
                url: '/geoserver/wms',
                version: '1.1.1',
				listeners: {
					ready: function(){
						app.loadAllLayers();
					}
				}
            },
			osm: {
				ptype: 'gxp_osmsource'
			},
            pgp: {
				ptype: 'gxp_pgpbasemapsource'
			},
            ol: {
                ptype: 'gxp_olsource'
            }
        },
        
        // map and layers
        map: {
            id: 'mymap', // id needed to reference map in portalConfig above,	
            center: [13523423.850079, 1637421.6270589],
            zoom: 2,
            controls: [
                new OpenLayers.Control.Zoom(),
                new OpenLayers.Control.Attribution(),
                new OpenLayers.Control.Navigation()
            ],

            layers: [ 

				{
					title: 'PGP Topographic Map',
					source: 'pgp',
					name: 'topo',
					group: 'background',
				},
				{
					title: 'Open Street Map',
					source: 'osm',
					name: 'mapnik',
					group: 'background',
				},
				{
					source: "ol",
					type: "OpenLayers.Layer",
					args: ["Blank"],
					visibility: true,
					group: "background"
				}
				
			]
        }
    });
	
	
	var maxExtent = new OpenLayers.Bounds(-20037508.34,-20037508.34,20037508.34,20037508.34);
	var layerMaxExtent = new OpenLayers.Bounds( 11516520.903064, 482870.29798867,  15821300.345956,  2448728.3963715);
	var units = 'm';
	var resolutions = [ 3968.75793751588, 
						2645.83862501058, 
						1322.91931250529, 
						661.459656252646, 
						264.583862501058, 
						132.291931250529, 
						66.1459656252646, 
						26.4583862501058, 
						13.2291931250529, 
						6.61459656252646, 
						2.64583862501058, 
						1.32291931250529, 
						0.661459656252646 ];
	var tileSize = new OpenLayers.Size(256, 256);
	var projection = 'EPSG:900913';
	var tileOrigin = new OpenLayers.LonLat(-20037508.342787,20037508.342787);
	var map = new OpenLayers.Map('map', {
		controls: [
					new OpenLayers.Control.Navigation(),
					new OpenLayers.Control.ScaleLine()
				]	,
		maxExtent: maxExtent,
		StartBounds: layerMaxExtent,
		units: units,
		resolutions: resolutions,
		tileSize: tileSize,
		projection: projection,
		restrictedExtent: layerMaxExtent,
		fallThrough: true,
		layers: [
		
			new OpenLayers.Layer("Blank", {isBaseLayer: true, visibility: false, displayInLayerSwitcher: false})
		
		]
	});
	

	app.mapPanel.map = map;
	

	
});

