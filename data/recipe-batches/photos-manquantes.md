# Photos manquantes — recettes publiées

Relevé du 2026-09-25 dans la base Supabase (projet Cuisine-du-monde) : recettes publiées sans photo `ready` dans `recipe_images`.

- Recettes publiées : 1303
- Avec photo : 866
- **Sans photo : 437** (130 pays)
  - 344 proviennent des lots `data/recipe-batches/` (migrations 12 à 22, générées sans `photos.json`)
  - 93 proviennent des migrations plus anciennes

Règle (PIPELINE.md §4) : chaque photo doit montrer ce plat précis, sous licence libre, avec auteur et licence conservés. Pour les recettes des lots, `node scripts/recipe-batches/find-photos.mjs` propose des candidates Commons à valider dans `photos.json`.

Légende : 🅱 = recette d'un lot local (nom anglais indiqué pour la recherche).

## Afghanistan (AF) — 3

- `ashak-afghan` — Ashak 🅱 — _Afghan aashak (leek dumplings with yogurt and meat sauce)_
- `bolani-afghan` — Bolani 🅱 — _Afghan bolani (potato and scallion stuffed flatbread)_
- `shor-nakhod-kaboul` — Shor nakhod 🅱 — _Kabul shor nakhod (chickpea and potato street salad)_

## Afrique du Sud (ZA) — 3

- `bunny-chow-durban` — Bunny chow 🅱 — _Durban bunny chow (bread bowl curry)_
- `chakalaka-sud-africain` — Chakalaka 🅱 — _South African chakalaka (spicy vegetable relish)_
- `koeksisters-sud-africains` — Koeksisters 🅱 — _South African koeksisters (syrup-soaked plaited doughnuts)_

## Andorre (AD) — 3

- `cargols-a-la-llauna` — Cargols a la llauna 🅱 — _Andorran cargols a la llauna (grilled snails with allioli)_
- `civet-de-senglar` — Civet de senglar 🅱 — _Andorran civet de senglar (wild boar stew in red wine)_
- `truita-de-carreroles` — Truita de carreroles 🅱 — _Andorran truita de carreroles (fairy ring mushroom omelette)_

## Angola (AO) — 5

- `cocada-amarela` — Cocada amarela 🅱 — _Angolan cocada amarela (coconut and egg-yolk pudding)_
- `funge-angolais` — Funge 🅱 — _Angolan funge (cassava porridge)_
- `mufete-de-luanda` — Mufete 🅱 — _Luanda mufete (grilled fish, palm-oil beans and plantains)_
- `None` — Muamba de galinha
- `None` — Calulu

## Arabie saoudite (SA) — 3

- `jareesh-najdi` — Jareesh 🅱 — _Najdi jareesh (cracked wheat with yogurt)_
- `kleija-qassim` — Kleija 🅱 — _Qassim kleija (date and cardamom cookies)_
- `mutabbaq-jeddah` — Mutabbaq 🅱 — _Jeddah mutabbaq (stuffed pan-fried pastry)_

## Argentine (AR) — 2

- `alfajores-de-maicena` — Alfajores de maicena 🅱 — _Argentine alfajores de maicena (dulce de leche sandwich cookies)_
- `locro-argentino` — Locro 🅱 — _Argentine locro (corn, squash and bean stew)_

## Arménie (AM) — 3

- `gata-armenienne` — Gata 🅱 — _Armenian gata (sweet buttery pastry)_
- `ghapama-armenienne` — Ghapama 🅱 — _Armenian ghapama (pumpkin stuffed with rice and dried fruit)_
- `harissa-armenienne` — Harissa (Arménie) 🅱 — _Armenian harissa (wheat and chicken porridge)_

## Australie (AU) — 1

- `damper-australien` — Damper 🅱 — _Australian damper (bush bread)_

## Azerbaïdjan (AZ) — 3

- `dushbara-azerbaidjan` — Düşbərə 🅱 — _Azerbaijani dushbara (tiny lamb dumpling soup)_
- `lavangi-lankaran` — Ləvəngi 🅱 — _Lankaran lavangi (chicken stuffed with walnuts and sour plums)_
- `piti-sheki` — Piti 🅱 — _Sheki piti (lamb and chickpea soup in a clay pot)_

## Bahamas (BS) — 5

- `chicken-souse-bahamas` — Chicken souse 🅱 — _Bahamian chicken souse (lime and chicken soup)_
- `guava-duff` — Guava duff 🅱 — _Bahamian guava duff (guava roll with rum sauce)_
- `johnnycake-bahamas` — Johnnycake 🅱 — _Bahamian johnnycake_
- `None` — Bahamian conch salad
- `None` — Bahamian peas n' rice

## Bahreïn (BH) — 3

- `gers-ogaily` — Gers ogaily 🅱 — _Bahraini gers ogaily (saffron cardamom cake)_
- `halwa-bahreinie` — Halwa bahreïnie 🅱 — _Bahraini halwa (saffron starch sweet with nuts)_
- `muhammar-bahrein` — Muhammar 🅱 — _Bahraini muhammar (sweet date-syrup rice)_

## Bangladesh (BD) — 3

- `mezbani-gosht` — Mezbani gosht 🅱 — _Chittagong mezbani beef curry_
- `shorshe-ilish` — Shorshe ilish 🅱 — _Bangladeshi shorshe ilish (hilsa in mustard sauce)_
- `None` — Bhuna khichuri bangladais

## Barbade (BB) — 5

- `bajan-fish-cakes` — Bajan fish cakes 🅱 — _Bajan fish cakes (salt cod fritters)_
- `conkies-barbade` — Conkies 🅱 — _Bajan conkies (cornmeal and coconut steamed in banana leaves)_
- `pudding-and-souse` — Pudding and souse 🅱 — _Bajan pudding and souse_
- `None` — Cou-cou and flying fish
- `None` — Bajan macaroni pie

## Belgique (BE) — 3

- `gaufres-de-liege` — Gaufre de Liège 🅱 — _Liège waffles (pearl sugar yeast waffles)_
- `stoemp-bruxellois` — Stoemp 🅱 — _Brussels stoemp (potato and vegetable mash with sausage)_
- `waterzooi-gantois` — Gentse waterzooi 🅱 — _Ghent waterzooi (creamy chicken and vegetable stew)_

## Belize (BZ) — 5

- `fry-jacks-belize` — Fry jacks 🅱 — _Belizean fry jacks_
- `hudut-dangriga` — Hudut 🅱 — _Garifuna hudut from Dangriga (fish in coconut broth with mashed plantain)_
- `salbutes-belize` — Salbutes 🅱 — _Belizean salbutes (puffed tortillas with chicken)_
- `None` — Belizean rice and beans with stew chicken
- `None` — Chimole

## Bhoutan (BT) — 3

- `jasha-maru` — Jasha maru 🅱 — _Bhutanese jasha maru (spicy chicken stew)_
- `phaksha-paa` — Phaksha paa 🅱 — _Bhutanese phaksha paa (pork with radish and dried chilies)_
- `shakam-paa` — Shakam paa 🅱 — _Bhutanese shakam paa (dried beef with chilies and radish)_

## Bolivie (BO) — 4

- `majadito-santa-cruz` — Majadito 🅱 — _Santa Cruz majadito (rice with dried beef, fried egg and plantain)_
- `pique-macho-cochabamba` — Pique macho 🅱 — _Cochabamba pique macho (spicy beef, sausage and fries)_
- `sopa-de-mani` — Sopa de maní 🅱 — _Bolivian sopa de maní (peanut soup)_
- `None` — Silpancho bolivien

## Bosnie-Herzégovine (BA) — 4

- `bosanski-lonac` — Bosanski lonac 🅱 — _Bosanski lonac (Bosnian meat and vegetable pot)_
- `cevapi-sarajevo` — Ćevapi (Sarajevski ćevapi) 🅱 — _Sarajevo ćevapi (grilled minced meat in somun bread)_
- `tufahija` — Tufahija 🅱 — _Bosnian tufahija (walnut-stuffed poached apples)_
- `None` — Begova čorba bosnienne

## Botswana (BW) — 5

- `dikgobe-botswana` — Dikgobe 🅱 — _Botswana dikgobe (sorghum and beans)_
- `magwinya-botswana` — Magwinya 🅱 — _Botswana magwinya (fat cakes)_
- `morogo-botswana` — Morogo 🅱 — _Botswana morogo (wild greens with tomato)_
- `None` — Bogobe jwa lerotse
- `None` — Seswaa

## Brunei (BN) — 3

- `kelupis-brunei` — Kelupis 🅱 — _Bruneian kelupis (coconut sticky rice in leaves)_
- `kuih-cincin` — Kuih cincin 🅱 — _Bruneian kuih cincin (palm sugar rings)_
- `udang-sambal-serai-lada` — Udang sambal serai lada 🅱 — _Bruneian udang sambal serai lada (lemongrass chili prawns)_

## Bulgarie (BG) — 2

- `kavarma-bulgare` — Kavarma 🅱 — _Bulgarian kavarma (clay-pot pork stew)_
- `tarator-bulgare` — Tarator 🅱 — _Bulgarian tarator (cold yogurt cucumber soup)_

## Cabo Verde (CV) — 3

- `caldo-de-peixe-cabo-verde` — Caldo de peixe 🅱 — _Cape Verdean caldo de peixe (fish and vegetable broth)_
- `canja-cap-verdienne` — Canja 🅱 — _Cape Verdean canja (chicken and rice soup)_
- `pastel-com-diabo-dentro` — Pastel com diabo dentro 🅱 — _Mindelo pastel com diabo dentro (spicy tuna pasties)_

## Cambodge (KH) — 4

- `bai-sach-chrouk` — Bai sach chrouk 🅱 — _Cambodian bai sach chrouk (coconut grilled pork and rice)_
- `kuy-teav-phnom-penh` — Kuy teav 🅱 — _Phnom Penh kuy teav (pork rice noodle soup)_
- `nom-banh-chok` — Nom banh chok 🅱 — _Cambodian nom banh chok (rice noodles with green fish curry)_
- `None` — Lok lak cambodgien au bœuf

## Cameroun (CM) — 4

- `eru-camerounais` — Eru 🅱 — _Cameroonian eru (okok leaves, waterleaf and palm oil)_
- `mbongo-tchobi` — Mbongo tchobi 🅱 — _Cameroonian mbongo tchobi (fish in black spice sauce)_
- `None` — Ndolé
- `None` — Poulet DG

## Canada (CA) — 1

- `butter-tarts-ontario` — Butter tarts 🅱 — _Ontario butter tarts_

## Chili (CL) — 3

- `cazuela-chilena` — Cazuela 🅱 — _Chilean cazuela (meat, corn and pumpkin soup)_
- `curanto-chiloe` — Curanto 🅱 — _Chiloé curanto (seafood and meat steamed with leaves)_
- `sopaipillas-chilenas` — Sopaipillas 🅱 — _Chilean sopaipillas (pumpkin fried dough)_

## Chypre (CY) — 5

- `afelia-chypriote` — Afelia 🅱 — _Cypriot afelia (pork in red wine and coriander seeds)_
- `kleftiko-chypriote` — Kleftiko 🅱 — _Cypriot kleftiko (slow-baked lamb)_
- `koupepia` — Koupepia 🅱 — _Cypriot koupepia (stuffed vine leaves)_
- `None` — Cypriot pork souvlaki
- `None` — Sheftaliés

## Colombie (CO) — 1

- `arepa-de-huevo` — Arepa de huevo 🅱 — _Luruaco arepa de huevo (egg-stuffed fried arepa)_

## Corée du Sud (KR) — 2

- `dak-galbi-chuncheon` — Dak-galbi 🅱 — _Chuncheon dak-galbi (spicy stir-fried chicken)_
- `dwaeji-gukbap-busan` — Dwaeji gukbap 🅱 — _Busan dwaeji gukbap (pork and rice soup)_

## Costa Rica (CR) — 4

- `chifrijo` — Chifrijo 🅱 — _San José chifrijo (rice, beans and crispy pork bowl)_
- `olla-de-carne` — Olla de carne 🅱 — _Costa Rican olla de carne (beef and root vegetable soup)_
- `rice-and-beans-limon` — Rice and beans limonense 🅱 — _Limón rice and beans (coconut rice with beans)_
- `None` — Casado costaricain au poulet

## Croatie (HR) — 4

- `fritule-croates` — Fritule 🅱 — _Croatian fritule (citrus and raisin doughnut bites)_
- `peka-dalmate` — Peka 🅱 — _Dalmatian peka (lamb and potatoes under the bell)_
- `zagorski-strukli` — Zagorski štrukli 🅱 — _Zagorje štrukli (cheese-filled pastry)_
- `None` — Crni rižot dalmate au calmar

## Cuba (CU) — 2

- `moros-y-cristianos` — Moros y cristianos 🅱 — _Cuban moros y cristianos (black beans and rice)_
- `yuca-con-mojo` — Yuca con mojo 🅱 — _Cuban yuca con mojo (cassava with garlic citrus sauce)_

## Côte d’Ivoire (CI) — 5

- `alloco-ivoirien` — Alloco 🅱 — _Ivorian alloco (fried plantains with chili sauce)_
- `garba-d-abidjan` — Garba 🅱 — _Abidjan garba (attiéké with fried tuna)_
- `sauce-graine-ivoirienne` — Sauce graine 🅱 — _Ivorian sauce graine (palm nut sauce with chicken)_
- `None` — Kédjénou
- `None` — Attiéké poisson grillé

## Danemark (DK) — 3

- `aebleskiver` — Æbleskiver 🅱 — _Danish æbleskiver (Christmas pancake puffs)_
- `rodgrod-med-flode` — Rødgrød med fløde 🅱 — _Danish rødgrød med fløde (red berry pudding with cream)_
- `stegt-flaesk-persillesovs` — Stegt flæsk med persillesovs 🅱 — _Danish stegt flæsk (crispy pork belly with parsley sauce)_

## Djibouti (DJ) — 4

- `fah-fah-djiboutien` — Fah-fah 🅱 — _Djiboutian fah-fah (spicy goat soup)_
- `poisson-yemenite-djibouti` — Poisson à la yéménite (mukbasa) 🅱 — _Djibouti Yemeni-style fish (tandoor-roasted fish with chili paste)_
- `sambusa-djiboutienne` — Sambusa 🅱 — _Djiboutian sambusa (fried minced-meat triangles)_
- `None` — Skoudehkaris

## Estonie (EE) — 2

- `mulgikapsad` — Mulgikapsad 🅱 — _Mulgi sauerkraut with pork and barley_
- `rosolje-estonien` — Rosolje 🅱 — _Estonian rosolje (beet and herring salad)_

## Fidji (FJ) — 5

- `fijian-chicken-curry` — Curry de poulet indo-fidjien 🅱 — _Indo-Fijian chicken curry_
- `lovo-fidji` — Lovo 🅱 — _Fijian lovo (earth oven feast)_
- `vakalolo` — Vakalolo 🅱 — _Fijian vakalolo (cassava pudding with coconut caramel)_
- `None` — Kokoda
- `None` — Rourou

## Finlande (FI) — 3

- `kalakukko-kuopio` — Kalakukko 🅱 — _Kuopio kalakukko (rye loaf filled with fish and pork)_
- `karjalanpaisti` — Karjalanpaisti 🅱 — _Karelian hot pot (karjalanpaisti)_
- `korvapuusti` — Korvapuusti 🅱 — _Finnish korvapuusti (cinnamon cardamom rolls)_

## Gambie (GM) — 2

- `benachin-gambien` — Benachin 🅱 — _Gambian benachin (one-pot fish and rice)_
- `domoda-gambien` — Domoda 🅱 — _Gambian domoda (beef and peanut stew)_

## Ghana (GH) — 3

- `kelewele-ghaneen` — Kelewele 🅱 — _Ghanaian kelewele (spiced fried plantains)_
- `red-red-ghaneen` — Red red 🅱 — _Ghanaian red red (black-eyed peas in palm oil with fried plantains)_
- `None` — Soupe ghanéenne aux arachides et poulet

## Guatemala (GT) — 5

- `hilachas-guatemaltecas` — Hilachas 🅱 — _Guatemalan hilachas (shredded beef in tomato sauce)_
- `jocon-guatemalteque` — Jocón 🅱 — _Guatemalan jocón (chicken in green tomatillo sauce)_
- `rellenitos-de-platano` — Rellenitos de plátano 🅱 — _Guatemalan rellenitos (plantain stuffed with sweet black beans)_
- `None` — Pepián
- `None` — Kak'ik

## Guyana (GY) — 5

- `guyanese-chicken-curry` — Guyanese chicken curry 🅱 — _Guyanese chicken curry_
- `metemgee` — Metemgee 🅱 — _Guyanese metemgee (coconut root vegetable stew)_
- `salara-guyana` — Salara 🅱 — _Guyanese salara (red coconut roll)_
- `None` — Guyanese cook-up rice
- `None` — Guyanese pepperpot

## Géorgie (GE) — 4

- `badrijani-nigvzit` — Badrijani nigvzit 🅱 — _Georgian badrijani nigvzit (eggplant rolls with walnuts)_
- `chakhokhbili` — Chakhokhbili 🅱 — _Georgian chakhokhbili (chicken stewed with tomatoes and herbs)_
- `lobio-georgien` — Lobio 🅱 — _Georgian lobio (spiced kidney beans)_
- `None` — Khinkali géorgiens à la viande

## Haïti (HT) — 5

- `akra-haitien` — Akra 🅱 — _Haitian akra (malanga fritters)_
- `diri-djon-djon` — Diri ak djon djon 🅱 — _Haitian diri ak djon djon (black mushroom rice)_
- `pikliz` — Pikliz 🅱 — _Haitian pikliz (spicy pickled slaw)_
- `None` — Soup joumou
- `None` — Griyo

## Honduras (HN) — 5

- `pastelitos-hondurenos` — Pastelitos de carne 🅱 — _Honduran pastelitos de carne (corn masa meat turnovers)_
- `plato-tipico-hondureno` — Plato típico 🅱 — _Honduran plato típico_
- `tapado-garifuna` — Tapado 🅱 — _Honduran Garifuna tapado (coconut seafood soup)_
- `None` — Baleadas
- `None` — Sopa de caracol

## Hongrie (HU) — 2

- `halaszle-szeged` — Halászlé 🅱 — _Szeged halászlé (spicy paprika fisherman's soup)_
- `None` — Paprikás csirke hongrois

## Irak (IQ) — 4

- `kleicha-irakiens` — Kleicha 🅱 — _Iraqi kleicha (date-filled cookies)_
- `kubbat-mosul` — Kubbat Mosul 🅱 — _Kubbat Mosul (large flat bulgur kibbeh)_
- `tepsi-baytinjan` — Tepsi baytinjan 🅱 — _Iraqi tepsi baytinjan (eggplant and meatball casserole)_
- `None` — Dolma irakien aux légumes farcis

## Iran (IR) — 3

- `ash-reshteh` — Ash reshteh 🅱 — _Iranian ash reshteh (noodle, herb and legume soup)_
- `joojeh-kabab` — Joojeh kabab 🅱 — _Iranian joojeh kabab (saffron chicken skewers)_
- `kashk-e-bademjan` — Kashk-e bademjan 🅱 — _Iranian kashk-e bademjan (eggplant dip with whey and mint)_

## Irlande (IE) — 1

- `None` — Boxty irlandais aux pommes de terre

## Islande (IS) — 4

- `kleinur-islandaises` — Kleinur 🅱 — _Icelandic kleinur (twisted cardamom doughnuts)_
- `ponnukokur-islandaises` — Pönnukökur 🅱 — _Icelandic pönnukökur (thin cinnamon pancakes)_
- `rugbraud-islandais` — Rúgbrauð 🅱 — _Icelandic rúgbrauð (steamed sweet rye bread)_
- `None` — Plokkfiskur islandais

## Israël (IL) — 3

- `malabi` — Malabi 🅱 — _Israeli malabi (rosewater milk pudding)_
- `meorav-yerushalmi` — Me'orav Yerushalmi 🅱 — _Me'orav Yerushalmi (Jerusalem mixed grill)_
- `sabich-israelien` — Sabich 🅱 — _Israeli sabich (fried eggplant and egg pita)_

## Jamaïque (JM) — 1

- `None` — Ackee and saltfish jamaïcain

## Jordanie (JO) — 3

- `galayet-bandora` — Galayet bandora 🅱 — _Jordanian galayet bandora (pan-fried tomatoes with garlic)_
- `kofta-bi-tahini` — Kofta bi tahini 🅱 — _Jordanian kofta bi tahini (baked kofta in tahini sauce)_
- `zarb-wadi-rum` — Zarb 🅱 — _Wadi Rum zarb (Bedouin underground-roasted lamb)_

## Kazakhstan (KZ) — 4

- `kespe-kazakh` — Kespe 🅱 — _Kazakh kespe (homemade noodle soup)_
- `manty-kazakh` — Manty 🅱 — _Kazakh manty (steamed lamb dumplings)_
- `sorpa-kazakh` — Sorpa 🅱 — _Kazakh sorpa (mutton broth)_
- `None` — Kuyrdak kazakh

## Kenya (KE) — 4

- `githeri-kenyan` — Githeri 🅱 — _Kenyan githeri (maize and bean stew)_
- `mandazi-swahili` — Mandazi 🅱 — _Kenyan mandazi (coconut and cardamom doughnuts)_
- `sukuma-wiki-kenyan` — Sukuma wiki 🅱 — _Kenyan sukuma wiki (sautéed collard greens)_
- `None` — Pilau kényan au bœuf

## Kirghizistan (KG) — 3

- `ashlan-fu-karakol` — Ashlan-fu 🅱 — _Karakol ashlyan-fu (cold noodle and starch jelly soup)_
- `lagman-kirghiz` — Lagman 🅱 — _Kyrgyz lagman (hand-pulled noodles with meat and vegetables)_
- `oromo-kirghiz` — Oromo 🅱 — _Kyrgyz oromo (steamed meat and pumpkin roll)_

## Laos (LA) — 4

- `mok-pa-lao` — Mok pa 🅱 — _Lao mok pa (steamed fish in banana leaf)_
- `or-lam-luang-prabang` — Or lam 🅱 — _Luang Prabang or lam (stew with eggplant and pepper wood)_
- `tam-mak-hoong` — Tam mak hoong 🅱 — _Lao tam mak hoong (pounded green papaya salad)_
- `None` — Khao piak sen lao

## Lettonie (LV) — 3

- `piragi-lettons` — Pīrāgi 🅱 — _Latvian pīrāgi (bacon and onion buns)_
- `rupjmaizes-kartojums` — Rupjmaizes kārtojums 🅱 — _Latvian rye bread trifle (rupjmaizes kārtojums)_
- `skabenu-zupa` — Skābeņu zupa 🅱 — _Latvian sorrel soup (skābeņu zupa)_

## Liban (LB) — 3

- `fattoush` — Fattoush 🅱 — _Lebanese fattoush (toasted bread salad with sumac)_
- `manakish-zaatar` — Manakish za'atar 🅱 — _Lebanese manakish za'atar (za'atar flatbread)_
- `None` — Kibbeh libanais au four

## Libye (LY) — 2

- `bazeen-libyen` — Bazeen 🅱 — _Libyan bazeen (barley dough dome with lamb sauce)_
- `sharba-libiya` — Sharba libiya 🅱 — _Libyan sharba (lamb and orzo soup with mint)_

## Libéria (LR) — 3

- `cassava-leaf-liberia` — Cassava leaf 🅱 — _Liberian cassava leaf stew_
- `potato-greens-liberia` — Potato greens 🅱 — _Liberian potato greens_
- `rice-bread-liberia` — Rice bread 🅱 — _Liberian rice bread (banana rice cake)_

## Liechtenstein (LI) — 3

- `apfelkuchle` — Apfelküchle 🅱 — _Liechtenstein Apfelküchle (apple fritters)_
- `hafalab` — Hafaläb 🅱 — _Liechtenstein Hafaläb (cornmeal dumpling with bacon)_
- `leberknodelsuppe` — Leberknödelsuppe 🅱 — _Liechtenstein liver dumpling soup_

## Lituanie (LT) — 3

- `balandeliai` — Balandėliai 🅱 — _Lithuanian balandėliai (stuffed cabbage rolls)_
- `kibinai-trakai` — Kibinai 🅱 — _Trakai kibinai (Karaim lamb pasties)_
- `kugelis-lituanien` — Kugelis 🅱 — _Lithuanian kugelis (potato pudding with bacon)_

## Luxembourg (LU) — 3

- `bouneschlupp` — Bouneschlupp 🅱 — _Luxembourg Bouneschlupp (green bean soup)_
- `kniddelen` — Kniddelen 🅱 — _Luxembourg Kniddelen (flour dumplings with bacon)_
- `rieslingspaschteit` — Rieslingspaschtéit 🅱 — _Luxembourg Rieslingspaschtéit (Riesling meat pie)_

## Macédoine du Nord (MK) — 3

- `ajvar` — Ajvar 🅱 — _Macedonian ajvar (roasted red pepper relish)_
- `ohridska-pastrmka` — Ohridska pastrmka 🅱 — _Ohrid trout baked with garlic and lemon_
- `selsko-meso` — Selsko meso 🅱 — _Macedonian selsko meso (village-style meat)_

## Madagascar (MG) — 5

- `akoho-sy-voanio` — Akoho sy voanio 🅱 — _Malagasy akoho sy voanio (chicken in coconut milk)_
- `koba-akondro` — Koba akondro 🅱 — _Malagasy koba akondro (banana and peanut cake in leaves)_
- `mofo-gasy` — Mofo gasy 🅱 — _Malagasy mofo gasy (coconut rice cakes)_
- `None` — Ravitoto
- `None` — Romazava

## Malaisie (MY) — 3

- `assam-laksa-penang` — Assam laksa 🅱 — _Penang assam laksa (tamarind fish noodle soup)_
- `roti-canai` — Roti canai 🅱 — _Malaysian roti canai with dhal_
- `None` — Char kway teow malaisien

## Malawi (MW) — 3

- `kondowole-malawien` — Kondowole 🅱 — _Malawian kondowole (cassava flour porridge)_
- `mandasi-malawien` — Mandasi 🅱 — _Malawian mandasi (breakfast doughnuts)_
- `ndiwo-za-nkhwani` — Nkhwani 🅱 — _Malawian nkhwani (pumpkin leaves with peanut flour)_

## Maldives (MV) — 3

- `bis-keemiya` — Bis keemiya 🅱 — _Maldivian bis keemiya (tuna and cabbage pastries)_
- `mas-riha` — Mas riha 🅱 — _Maldivian mas riha (tuna curry)_
- `masroshi` — Masroshi 🅱 — _Maldivian masroshi (tuna and coconut stuffed flatbreads)_

## Malte (MT) — 4

- `imqaret` — Imqaret 🅱 — _Maltese imqaret (date-filled fried pastries)_
- `stuffat-tal-fenek` — Stuffat tal-fenek 🅱 — _Maltese stuffat tal-fenek (rabbit stew)_
- `torta-tal-lampuki` — Torta tal-lampuki 🅱 — _Maltese lampuki pie (dorado fish pie)_
- `None` — Ftira Għawdxija

## Maroc (MA) — 2

- `tajine-poulet-citron-olives` — Tajine de poulet aux citrons confits et olives 🅱 — _Moroccan chicken tagine with preserved lemons and olives_
- `tanjia-marrakchia` — Tanjia marrakchia 🅱 — _Marrakech tanjia (slow-cooked beef in a clay urn)_

## Maurice (MU) — 5

- `gateaux-piments-maurice` — Gâteaux piments 🅱 — _Mauritian gâteaux piments (split pea chili fritters)_
- `rougaille-saucisses-maurice` — Rougaille saucisses 🅱 — _Mauritian rougaille with sausages (spicy tomato sauce)_
- `vindaye-poisson-maurice` — Vindaye de poisson 🅱 — _Mauritian fish vindaye (fried fish in mustard-turmeric pickle)_
- `None` — Dholl puri
- `None` — Mine frit

## Moldavie (MD) — 3

- `coltunasi-moldaves` — Colțunași 🅱 — _Moldovan colțunași (cheese dumplings)_
- `mamaliga-moldave` — Mămăligă cu brânză și smântână 🅱 — _Moldovan mămăligă with cheese and sour cream_
- `parjoale-moldaves` — Pârjoale 🅱 — _Moldovan pârjoale (herbed meat patties)_

## Mongolie (MN) — 4

- `boortsog-mongol` — Boortsog 🅱 — _Mongolian boortsog (fried butter cookies)_
- `khorkhog-mongol` — Khorkhog 🅱 — _Mongolian khorkhog (mutton cooked with hot stones)_
- `khuushuur-mongol` — Khuushuur 🅱 — _Mongolian khuushuur (fried mutton pastries)_
- `None` — Tsuivan mongol

## Monténégro (ME) — 4

- `buzara-boka` — Buzara 🅱 — _Boka Kotorska buzara (mussels in white wine and garlic)_
- `cicvara` — Cicvara 🅱 — _Montenegrin cicvara (cornmeal with young cheese)_
- `njeguski-raznjic` — Njeguški ražanj 🅱 — _Njeguši ražanj (pork stuffed with prosciutto and cheese)_
- `None` — Jagnjetina ispod sača

## Mozambique (MZ) — 3

- `bolo-polana` — Bolo polana 🅱 — _Maputo bolo polana (cashew and potato cake)_
- `camarao-piri-piri` — Camarão grelhado piri-piri 🅱 — _Mozambican grilled piri-piri prawns_
- `chamucas-mocambicanas` — Chamuças 🅱 — _Mozambican chamuças (spiced meat samosas)_

## Myanmar (MM) — 4

- `kyet-thar-hin` — Kyet thar hin 🅱 — _Burmese kyet thar hin (chicken curry)_
- `ohn-no-khao-swe` — Ohn no khao swè 🅱 — _Burmese ohn no khao swè (coconut chicken noodles)_
- `shan-khao-swe` — Shan khao swè 🅱 — _Shan noodles (rice noodles with tomato pork sauce)_
- `None` — Laphet thoke birman

## Namibie (NA) — 3

- `omboga-namibien` — Omboga 🅱 — _Namibian omboga (wild spinach with onion)_
- `oshifima-namibien` — Oshifima 🅱 — _Owambo oshifima (mahangu millet porridge)_
- `vetkoek-namibien` — Vetkoek 🅱 — _Namibian vetkoek (fried bread with savory mince)_

## Nicaragua (NI) — 4

- `indio-viejo` — Indio viejo 🅱 — _Nicaraguan indio viejo (shredded beef in corn masa stew)_
- `rondon-bluefields` — Rondón (run down) 🅱 — _Bluefields rondón (coconut fish and root vegetable stew)_
- `vigoron-granada` — Vigorón 🅱 — _Granada vigorón (cassava, pork cracklings and cabbage slaw)_
- `None` — Nacatamal nicaraguayen

## Norvège (NO) — 4

- `bergensk-fiskesuppe` — Bergensk fiskesuppe 🅱 — _Bergen fish soup (bergensk fiskesuppe)_
- `lapskaus-norvegien` — Lapskaus 🅱 — _Norwegian lapskaus (meat and root vegetable stew)_
- `raspeballer` — Raspeballer 🅱 — _Norwegian raspeballer (potato dumplings)_
- `None` — Kjøttkaker norvégiennes

## Nouvelle-Zélande (NZ) — 4

- `hangi` — Hāngī 🅱 — _Māori hāngī (earth oven feast)_
- `whitebait-fritters` — Whitebait fritters 🅱 — _West Coast whitebait fritters_
- `None` — Parāoa rēwena
- `None` — Māori boil-up

## Népal (NP) — 4

- `aloo-tama` — Aloo tama 🅱 — _Nepali aloo tama (potato, bamboo shoot and bean curry)_
- `sel-roti` — Sel roti 🅱 — _Nepali sel roti (sweet rice doughnut rings)_
- `yomari-katmandou` — Yomari 🅱 — _Kathmandu yomari (rice dumplings with molasses and sesame)_
- `None` — Dal bhat népalais

## Oman (OM) — 4

- `halwa-omanaise` — Halwa omanaise 🅱 — _Omani halwa (saffron and rosewater sweet)_
- `mashuai-omanais` — Mashuai 🅱 — _Omani mashuai (grilled kingfish with lemon rice)_
- `mishkak-omanais` — Mishkak 🅱 — _Omani mishkak (tamarind beef skewers)_
- `None` — Majboos

## Ouganda (UG) — 4

- `katogo-ougandais` — Katogo 🅱 — _Ugandan katogo (green banana one-pot)_
- `malewa-bugisu` — Malewa 🅱 — _Bugisu malewa (smoked bamboo shoots in peanut sauce)_
- `matoke-ougandais` — Matoke 🅱 — _Ugandan matoke (mashed green bananas)_
- `None` — Luwombo ougandais au poulet

## Ouzbékistan (UZ) — 4

- `samsa-ouzbek` — Samsa 🅱 — _Uzbek samsa (tandoor-baked lamb pastries)_
- `shurpa-ouzbek` — Shurpa 🅱 — _Uzbek shurpa (lamb vegetable soup)_
- `tuxum-barak-khorezm` — Tuxum barak 🅱 — _Khorezm tukhum barak (egg-filled dumplings)_
- `None` — Manti ouzbeks à l’agneau

## Pakistan (PK) — 3

- `chapli-kebab-peshawar` — Chapli kebab 🅱 — _Peshawari chapli kebab_
- `sindhi-biryani` — Sindhi biryani 🅱 — _Sindhi biryani_
- `None` — Chicken karahi pakistanais

## Palestine (PS) — 4

- `knafeh-nabulsieh` — Knafeh nabulsieh 🅱 — _Nablus knafeh (sweet cheese pastry)_
- `maftoul-palestinien` — Maftoul 🅱 — _Palestinian maftoul (hand-rolled couscous with chicken and chickpeas)_
- `musakhan-palestinien` — Musakhan 🅱 — _Palestinian musakhan (sumac roast chicken on taboun bread)_
- `sumagiyya-gaza` — Sumagiyya 🅱 — _Gaza sumagiyya (lamb and chard stew with sumac and tahini)_

## Panama (PA) — 4

- `carimanolas` — Carimañolas 🅱 — _Panamanian carimañolas (meat-stuffed yuca fritters)_
- `hojaldras-panamenas` — Hojaldras 🅱 — _Panamanian hojaldras (fried dough)_
- `None` — Arroz con pollo panameño
- `None` — Sancocho de gallina panameño

## Papouasie–Nouvelle-Guinée (PG) — 3

- `aigir-east-new-britain` — Aigir 🅱 — _East New Britain aigir (coconut chicken and vegetables cooked with hot stones)_
- `kaukau-coco-png` — Kaukau 🅱 — _Papua New Guinean kaukau (sweet potato in coconut milk)_
- `saksak` — Saksak 🅱 — _Sepik saksak (sago and banana dumplings)_

## Paraguay (PY) — 5

- `chipa-guasu` — Chipa guasu 🅱 — _Paraguayan chipa guasu (fresh corn and cheese bake)_
- `mbeju` — Mbejú 🅱 — _Paraguayan mbejú (cassava starch and cheese flatbread)_
- `vori-vori` — Vori vori 🅱 — _Paraguayan vori vori (chicken soup with corn and cheese dumplings)_
- `None` — Chipa
- `None` — Sopa paraguaya

## Pays-Bas (NL) — 4

- `erwtensoep` — Erwtensoep (snert) 🅱 — _Dutch erwtensoep (thick split pea soup)_
- `poffertjes` — Poffertjes 🅱 — _Dutch poffertjes (mini buckwheat pancakes)_
- `stroopwafels-gouda` — Stroopwafels 🅱 — _Gouda stroopwafels (caramel syrup waffles)_
- `None` — Bitterballen néerlandaises

## Philippines (PH) — 1

- `None` — Sinigang na baboy philippin

## Pologne (PL) — 3

- `golabki-polonais` — Gołąbki 🅱 — _Polish gołąbki (stuffed cabbage rolls)_
- `zurek-polonais` — Żurek 🅱 — _Polish żurek (sour rye soup)_
- `None` — Bigos polonais

## Portugal (PT) — 2

- `francesinha-porto` — Francesinha 🅱 — _Porto francesinha (sauced meat sandwich)_
- `pasteis-de-nata-lisboa` — Pastéis de nata 🅱 — _Lisbon pastéis de nata (custard tarts)_

## Roumanie (RO) — 4

- `mici-roumains` — Mici (mititei) 🅱 — _Romanian mici (grilled garlicky skinless sausages)_
- `papanasi` — Papanași 🅱 — _Romanian papanași (cheese doughnuts with cream and jam)_
- `zacusca` — Zacuscă 🅱 — _Romanian zacuscă (roasted pepper and eggplant spread)_
- `None` — Ciorbă de perișoare roumaine

## Rwanda (RW) — 2

- `agatogo-rwandais` — Agatogo 🅱 — _Rwandan agatogo (plantain and meat stew)_
- `ibiharage-rwandais` — Ibiharage 🅱 — _Rwandan ibiharage (fried beans with onion)_

## République dominicaine (DO) — 3

- `sancocho-dominicano` — Sancocho dominicano 🅱 — _Dominican sancocho (hearty meat and root vegetable stew)_
- `None` — La Bandera Dominicana
- `None` — Mangú

## République démocratique du Congo (CD) — 1

- `pondu-congolais` — Pondu (saka-saka) 🅱 — _Congolese pondu (cassava leaves)_

## Salvador (SV) — 5

- `panes-con-pollo` — Panes con pollo 🅱 — _Salvadoran panes con pollo (saucy chicken sandwiches)_
- `quesadilla-salvadorena` — Quesadilla salvadoreña 🅱 — _Salvadoran quesadilla (cheese pound cake)_
- `sopa-de-pata` — Sopa de pata 🅱 — _Salvadoran sopa de pata (cow foot soup)_
- `None` — Yuca frita con chicharrón
- `None` — Pupusas revueltas

## Samoa (WS) — 3

- `koko-alaisa` — Koko alaisa 🅱 — _Samoan koko alaisa (cocoa rice)_
- `panipopo` — Panipopo 🅱 — _Samoan panipopo (coconut caramel buns)_
- `sapasui` — Sapasui 🅱 — _Samoan sapasui (chop suey)_

## Serbie (RS) — 4

- `karadjordjeva-snicla` — Karađorđeva šnicla 🅱 — _Belgrade Karađorđeva šnicla (breaded kajmak-stuffed schnitzel)_
- `pasulj` — Pasulj 🅱 — _Serbian pasulj (bean stew with smoked meat)_
- `pljeskavica-leskovac` — Leskovačka pljeskavica 🅱 — _Leskovac pljeskavica (spicy grilled meat patty)_
- `None` — Gibanica serbe au fromage

## Singapour (SG) — 4

- `hokkien-mee-singapour` — Hokkien mee 🅱 — _Singapore Hokkien mee (prawn and squid fried noodles)_
- `katong-laksa` — Katong laksa 🅱 — _Katong laksa (coconut curry noodle soup)_
- `kaya-toast` — Kaya toast 🅱 — _Singapore kaya toast_
- `None` — Chili crab de Singapour

## Slovaquie (SK) — 4

- `cesnakova-polievka` — Cesnaková polievka 🅱 — _Slovak cesnaková polievka (garlic soup)_
- `lokse-slovaques` — Lokše 🅱 — _Slovak lokše (potato flatbreads)_
- `parene-buchty` — Parené buchty 🅱 — _Slovak parené buchty (steamed plum-filled buns)_
- `None` — Kapustnica slovaque

## Slovénie (SI) — 5

- `idrijski-zlikrofi` — Idrijski žlikrofi 🅱 — _Idrija žlikrofi (potato dumplings)_
- `potica` — Potica 🅱 — _Slovenian potica (walnut roll)_
- `prekmurska-gibanica` — Prekmurska gibanica 🅱 — _Prekmurje gibanica (layered poppy, cheese, walnut and apple cake)_
- `None` — Kraška jota
- `None` — Skutni štruklji

## Somalie (SO) — 3

- `cambuulo-somali` — Cambuulo 🅱 — _Somali cambuulo (azuki beans with butter and sugar)_
- `muufo-somali` — Muufo 🅱 — _Somali muufo (cornmeal flatbread)_
- `suqaar-somali` — Suqaar 🅱 — _Somali suqaar (beef stir-fry with vegetables and xawaash)_

## Sri Lanka (LK) — 4

- `appa-sri-lankais` — Appa (hoppers) 🅱 — _Sri Lankan hoppers (appa) with egg_
- `kiribath` — Kiribath 🅱 — _Sri Lankan kiribath (coconut milk rice)_
- `parippu-sri-lankais` — Parippu 🅱 — _Sri Lankan parippu (red lentil coconut dhal)_
- `None` — Fish ambul thiyal sri-lankais

## Suisse (CH) — 4

- `engadiner-nusstorte` — Engadiner Nusstorte 🅱 — _Engadine walnut tart (Engadiner Nusstorte)_
- `raclette-valais` — Raclette du Valais 🅱 — _Valais raclette (melted cheese with potatoes)_
- `zurcher-geschnetzeltes` — Zürcher Geschnetzeltes 🅱 — _Zürcher Geschnetzeltes (Zurich-style veal in cream sauce)_
- `None` — Fondue suisse moitié-moitié

## Suriname (SR) — 5

- `bara-suriname` — Bara 🅱 — _Surinamese bara (split pea fritters)_
- `moksi-alesi` — Moksi alesi 🅱 — _Surinamese moksi alesi (mixed rice)_
- `saoto-soep` — Saoto soep 🅱 — _Surinamese saoto soup (Javanese chicken soup)_
- `None` — Surinamese pom
- `None` — Surinamese chicken roti

## Suède (SE) — 2

- `kanelbullar` — Kanelbullar 🅱 — _Swedish kanelbullar (cinnamon buns)_
- `None` — Janssons frestelse suédoise

## Sénégal (SN) — 3

- `mafe-senegalais` — Mafé 🅱 — _Senegalese mafé (peanut stew)_
- `pastels-senegalais` — Pastels 🅱 — _Senegalese pastels (fish-filled fried pastries)_
- `thiakry` — Thiakry 🅱 — _Senegalese thiakry (millet couscous with sweetened yogurt)_

## Tadjikistan (TJ) — 3

- `sambusa-tadjik` — Sambusa 🅱 — _Tajik sambusa (baked lamb pastries)_
- `shirchoy-tadjik` — Shirchoy 🅱 — _Tajik shirchoy (salted milk tea with butter)_
- `shurbo-tadjik` — Shurbo 🅱 — _Tajik shurbo (lamb and vegetable soup)_

## Tanzanie (TZ) — 4

- `mishkaki-tanzanien` — Mishkaki 🅱 — _Tanzanian mishkaki (marinated beef skewers)_
- `ndizi-nyama` — Ndizi nyama 🅱 — _Tanzanian ndizi nyama (green banana and beef stew)_
- `urojo-zanzibar` — Urojo (Zanzibar mix) 🅱 — _Zanzibar urojo (tangy mango soup with fritters)_
- `None` — Chipsi mayai tanzanien

## Taïwan (TW) — 3

- `lu-rou-fan` — Lu rou fan 🅱 — _Taiwanese lu rou fan (braised pork rice)_
- `niu-rou-mian` — Niu rou mian 🅱 — _Taiwanese beef noodle soup (niu rou mian)_
- `san-bei-ji` — San bei ji 🅱 — _Taiwanese three-cup chicken (san bei ji)_

## Tchad (TD) — 5

- `aiysh-tchadien` — Aiysh (boule de mil) 🅱 — _Chadian aiysh (millet boule with okra sauce)_
- `daraba-tchadien` — Daraba 🅱 — _Chadian daraba (okra and vegetable stew with peanut butter)_
- `karkanji-tchadien` — Karkanji 🅱 — _Chadian karkanji (hibiscus and ginger drink)_
- `kissar-tchadien` — Kissar 🅱 — _Chadian kissar (thin fermented sorghum flatbreads)_
- `mashwi-tchadien` — Mashwi 🅱 — _Chadian mashwi (spiced beef skewers)_

## Tchéquie (CZ) — 3

- `bramboraky` — Bramboráky 🅱 — _Czech bramboráky (garlic potato pancakes)_
- `smazeny-syr` — Smažený sýr 🅱 — _Czech smažený sýr (fried breaded cheese)_
- `vepro-knedlo-zelo` — Vepřo knedlo zelo 🅱 — _Czech vepřo knedlo zelo (roast pork, dumplings and cabbage)_

## Timor-Leste (TL) — 3

- `feijoada-timorense` — Feijoada timorense 🅱 — _Timorese feijoada (pork and bean stew)_
- `katupa-timor` — Katupa 🅱 — _Timorese katupa (coconut rice in woven palm leaves)_
- `tukir-timor` — Tukir 🅱 — _Timorese tukir (meat cooked in bamboo)_

## Trinité-et-Tobago (TT) — 5

- `bake-and-shark-maracas` — Bake and shark 🅱 — _Maracas Bay bake and shark_
- `curry-crab-and-dumpling` — Curry crab and dumpling 🅱 — _Tobago curry crab and dumpling_
- `pelau-trinidad` — Pelau 🅱 — _Trinidadian pelau (caramelized chicken and pigeon pea rice)_
- `None` — Trinidad doubles
- `None` — Trinidad and Tobago callaloo

## Tunisie (TN) — 4

- `couscous-poisson-sfax` — Couscous au poisson 🅱 — _Sfax fish couscous (grouper in spicy tomato broth)_
- `kafteji-tunisien` — Kafteji 🅱 — _Tunisian kafteji (chopped fried vegetables with egg)_
- `lablabi-tunisien` — Lablabi 🅱 — _Tunis lablabi (chickpea soup with bread and harissa)_
- `None` — Brik tunisien à l’œuf et au thon

## Ukraine (UA) — 4

- `banosh-carpates` — Banosh 🅱 — _Carpathian banosh (cornmeal with cream, brynza and cracklings)_
- `deruny-ukrainiens` — Deruny 🅱 — _Ukrainian deruny (potato pancakes)_
- `syrnyky-ukrainiens` — Syrnyky 🅱 — _Ukrainian syrnyky (farmer's cheese pancakes)_
- `None` — Varenyky ukrainiens aux pommes de terre

## Uruguay (UY) — 4

- `chaja-paysandu` — Chajá 🅱 — _Paysandú chajá (sponge, meringue, cream and peach cake)_
- `torta-frita-uruguaya` — Torta frita 🅱 — _Uruguayan torta frita (fried dough)_
- `None` — Asado uruguayo
- `None` — Chivito uruguayo

## Vanuatu (VU) — 3

- `nalot` — Nalot 🅱 — _Vanuatu nalot (pounded taro or banana with coconut)_
- `simboro` — Simboro 🅱 — _Vanuatu simboro (leaf rolls with cassava and coconut)_
- `tuluk-vanuatu` — Tuluk 🅱 — _Vanuatu tuluk (cassava parcels with pork)_

## Venezuela (VE) — 2

- `cachapa-venezolana` — Cachapa 🅱 — _Venezuelan cachapa (fresh corn pancake with cheese)_
- `None` — Arepas reina pepiada vénézuéliennes

## Viêt Nam (VN) — 1

- `cao-lau-hoi-an` — Cao lầu 🅱 — _Hội An cao lầu (pork and herb noodles)_

## Yémen (YE) — 2

- `fahsa-sanaa` — Fahsa 🅱 — _Sanaa fahsa (bubbling shredded lamb stew with fenugreek froth)_
- `mandi-hadramaout` — Mandi 🅱 — _Hadhramaut mandi (smoked lamb over spiced rice)_

## Zambie (ZM) — 3

- `chikanda-zambien` — Chikanda 🅱 — _Zambian chikanda (African polony)_
- `ifisashi-zambien` — Ifisashi 🅱 — _Zambian ifisashi (greens in peanut sauce)_
- `vitumbuwa-zambiens` — Vitumbuwa 🅱 — _Zambian vitumbuwa (small fritters)_

## Zimbabwe (ZW) — 3

- `muriwo-une-dovi` — Muriwo une dovi 🅱 — _Zimbabwean muriwo une dovi (greens with peanut butter)_
- `nhopi-zimbabween` — Nhopi 🅱 — _Zimbabwean nhopi (pumpkin mash with peanut butter)_
- `rupiza-zimbabween` — Rupiza 🅱 — _Zimbabwean rupiza (pea and bean mash)_

## Émirats arabes unis (AE) — 3

- `chebab-emirati` — Chebab 🅱 — _Emirati chebab (saffron and cardamom pancakes)_
- `saloona-emirati` — Saloona 🅱 — _Emirati saloona (chicken and vegetable stew)_
- `thareed-emirati` — Thareed 🅱 — _Emirati thareed (lamb stew over regag bread)_

## Équateur (EC) — 4

- `bolon-de-verde` — Bolón de verde 🅱 — _Ecuadorian bolón de verde (green plantain balls with cheese)_
- `locro-de-papa` — Locro de papa 🅱 — _Ecuadorian locro de papa (potato and cheese soup)_
- `seco-de-chivo` — Seco de chivo 🅱 — _Ecuadorian seco de chivo (goat stew)_
- `None` — Llapingachos équatoriens

## Érythrée (ER) — 3

- `gaat-erythreen` — Ga'at 🅱 — _Eritrean ga'at (barley porridge with spiced butter)_
- `kitcha-fit-fit` — Kitcha fit-fit 🅱 — _Eritrean kitcha fit-fit (shredded flatbread with spiced butter)_
- `shiro-erythreen` — Shiro 🅱 — _Eritrean shiro (spiced chickpea stew)_

## Éthiopie (ET) — 2

- `gomen-ethiopien` — Gomen 🅱 — _Ethiopian gomen (collard greens with garlic and ginger)_
- `kitfo-gurage` — Kitfo 🅱 — _Gurage kitfo (minced beef with spiced butter and mitmita)_
