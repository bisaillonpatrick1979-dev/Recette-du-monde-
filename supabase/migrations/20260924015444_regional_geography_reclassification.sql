-- Reclassement géographique des recettes
-- 1. Les recettes sans origine identifiable deviennent des « Classiques sans frontières »
-- 2. Nouvelles régions / villes pour zoomer sur les spécialités locales
-- 3. Correction des recettes rangées dans le mauvais pays (ex. « chili » Texas classé au Chili)
-- 4. Rattachement aux régions / villes d'origine connues
-- 5. Spécialités de lieu générées pour les recettes régionales (affichées sur le globe)

alter table public.recipes
  add column if not exists is_borderless boolean not null default false;

comment on column public.recipes.is_borderless is
  'Classique sans frontières : recette internationale sans origine géographique précise.';

create index if not exists recipes_borderless_idx
  on public.recipes(is_borderless) where is_borderless;

-- Pays manquant
insert into public.culinary_places (slug, name, country_code, place_type, latitude, longitude, default_zoom, summary)
values ('ps', 'Palestine', 'PS', 'country', 31.9522, 35.2332, 7,
        'Cuisine palestinienne : musakhan, maqluba, knafeh de Naplouse et pain taboon.')
on conflict (slug) do nothing;

-- Lieux parents présents en production mais créés hors des migrations suivies :
-- on les garantit pour qu'une base neuve puisse rejouer cette migration.
insert into public.culinary_places (slug, name, country_code, place_type, latitude, longitude, default_zoom, summary)
values
  ('royaume-uni', 'Royaume-Uni', 'GB', 'country', 54.0000, -2.5000, 5,
   'Cuisine britannique : tourtes, rôtis du dimanche, puddings, fish and chips et heure du thé.'),
  ('uruguay', 'Uruguay', 'UY', 'country', -32.5228, -55.7658, 6,
   'Cuisine uruguayenne : asado, chivito, dulce de leche et maté.')
on conflict (slug) do nothing;

insert into public.culinary_places (slug, name, country_code, place_type, parent_id, latitude, longitude, default_zoom, summary)
select v.slug, v.name, 'GB', v.place_type, p.id, v.latitude, v.longitude, v.default_zoom, v.summary
from (values
  ('londres', 'Londres', 'city', 51.5074, -0.1278, 10, 'Pubs, marchés, cuisine du monde et grands classiques britanniques.'),
  ('cornouailles', 'Cornouailles', 'region', 50.2660, -5.0527, 8, 'Cornish pasties, stargazy pie, crème caillée et fruits de mer.')
) as v(slug, name, place_type, latitude, longitude, default_zoom, summary)
join public.culinary_places p on p.slug = 'royaume-uni'
on conflict (slug) do nothing;

-- Nouvelles régions et villes (depth 1 = parent déjà existant, depth 2 = parent créé au niveau 1)
with new_places(depth, slug, name, country_code, place_type, parent_slug, latitude, longitude, default_zoom, summary) as (
  values
  (1, 'fr-provence', 'Provence-Alpes-Côte d''Azur', 'FR', 'region', 'fr', 43.9352, 6.0679, 7, 'Huile d''olive, ail, herbes de Provence, tomates et poissons de roche.'),
  (1, 'fr-savoie', 'Savoie', 'FR', 'region', 'fr', 45.4933, 6.4700, 8, 'Fromages d''alpage (reblochon, beaufort), tartiflette, fondue et raclette.'),
  (1, 'fr-centre-val-de-loire', 'Centre-Val de Loire', 'FR', 'region', 'fr', 47.7516, 1.6751, 7, 'Gibier de Sologne, fromages de chèvre et tarte Tatin.'),
  (1, 'fr-ile-de-france', 'Île-de-France', 'FR', 'region', 'fr', 48.8499, 2.6370, 8, 'Bistrots, brasseries et grandes pâtisseries de la capitale.'),
  (1, 'fr-bretagne', 'Bretagne', 'FR', 'region', 'fr', 48.2020, -2.9326, 7, 'Crêpes et galettes de sarrasin, beurre salé, fruits de mer et cidre.'),
  (1, 'fr-pays-de-la-loire', 'Pays de la Loire', 'FR', 'region', 'fr', 47.7633, -0.3300, 7, 'Beurre blanc, muscadet, maraîchage nantais et rillettes.'),
  (1, 'gb-scotland', 'Écosse', 'GB', 'region', 'royaume-uni', 56.4907, -4.2026, 6, 'Haggis, saumon, shortbread, porridge et scones de pommes de terre.'),
  (1, 'gb-england', 'Angleterre', 'GB', 'region', 'royaume-uni', 52.3555, -1.1743, 6, 'Tourtes, rôtis du dimanche, puddings et heure du thé.'),
  (1, 'ie-dublin', 'Dublin', 'IE', 'city', 'ie', 53.3498, -6.2603, 11, 'Coddle, pubs historiques, stout et pain au bicarbonate.'),
  (1, 'us-texas', 'Texas', 'US', 'region', 'us', 31.0000, -99.9000, 5.5, 'Chili con carne, brisket fumé, fajitas et Tex-Mex.'),
  (1, 'us-massachusetts', 'Massachusetts', 'US', 'region', 'us', 42.4072, -71.3824, 7, 'Nouvelle-Angleterre : fèves au lard, chaudrée de palourdes et cookies aux pépites de chocolat.'),
  (1, 'us-maryland', 'Maryland', 'US', 'region', 'us', 39.0458, -76.6413, 7, 'Baie de Chesapeake : crabes bleus, crab cakes et épices Old Bay.'),
  (1, 'us-ohio', 'Ohio', 'US', 'region', 'us', 40.4173, -82.9071, 7, 'L''État du marronnier : buckeyes chocolat-arachide et chili de Cincinnati.'),
  (1, 'us-utah', 'Utah', 'US', 'region', 'us', 39.3210, -111.0937, 6, 'Cuisine de rassemblement : funeral potatoes, frog eye salad et gelées.'),
  (1, 'us-ozarks', 'Ozarks', 'US', 'region', 'us', 36.5000, -92.6000, 7, 'Plateau du Missouri et de l''Arkansas : pudding des Ozarks et cuisine rurale.'),
  (1, 'us-oregon', 'Oregon', 'US', 'region', 'us', 43.8041, -120.5542, 6, 'Nord-Ouest Pacifique : saumon, petits fruits, noisettes et pancakes de Portland.'),
  (1, 'us-washington', 'État de Washington', 'US', 'region', 'us', 47.7511, -120.7401, 6, 'Saumon sauvage grillé sur planche de cèdre, pommes et fruits de mer.'),
  (1, 'us-california', 'Californie', 'US', 'region', 'us', 36.7783, -119.4179, 5.5, 'Cuisine fusion, avocats, agrumes, vins et cioppino.'),
  (1, 'us-new-york', 'État de New York', 'US', 'region', 'us', 42.9538, -75.5268, 6, 'Bagels, cheesecake, delis et ailes de poulet de Buffalo.'),
  (1, 'us-pennsylvania', 'Pennsylvanie', 'US', 'region', 'us', 41.2033, -77.1945, 6, 'Cuisine amish, cheesesteak de Philadelphie et banana split.'),
  (1, 'us-south', 'Sud des États-Unis', 'US', 'region', 'us', 33.5000, -86.5000, 5, 'Soul food : biscuits and gravy, chou cavalier, patates douces et poulet frit.'),
  (1, 'us-new-mexico', 'Nouveau-Mexique', 'US', 'region', 'us', 34.5199, -105.8701, 6, 'Piments de Hatch, burritos du matin et cuisine hispano-pueblo.'),
  (1, 'us-arizona', 'Arizona', 'US', 'region', 'us', 34.0489, -111.0937, 6, 'Nation navajo : frybread, maïs, courges et piments.'),
  (1, 'us-hawaii', 'Hawaï', 'US', 'island', 'us', 20.7984, -156.3319, 6, 'Poke, haupia, kalua pig et influences polynésiennes et asiatiques.'),
  (1, 'ca-vancouver', 'Vancouver', 'CA', 'city', 'ca-british-columbia', 49.2827, -123.1207, 11, 'Saumon, sushis, cuisine asiatique et desserts légers.'),
  (1, 'mx-baja-california', 'Basse-Californie', 'MX', 'region', 'mx', 30.8406, -115.2838, 6, 'Tacos de poisson, vins de Guadalupe et salade César.'),
  (1, 'mx-jalisco', 'Jalisco', 'MX', 'region', 'mx', 20.6595, -103.3494, 7, 'Pozole, birria, tortas ahogadas et tequila.'),
  (1, 'it-sicilia', 'Sicile', 'IT', 'island', 'it', 37.5999, 14.0154, 7, 'Arancini, cannoli, caponata, pâtes aux sardines et agrumes.'),
  (1, 'it-lazio', 'Latium', 'IT', 'region', 'it', 41.8928, 12.4837, 7, 'Cuisine romaine : carbonara, cacio e pepe, amatriciana.'),
  (1, 'it-emilia-romagna', 'Émilie-Romagne', 'IT', 'region', 'it', 44.5968, 11.2186, 7, 'Parmesan, vinaigre balsamique de Modène, lasagnes et tagliatelles.'),
  (1, 'it-veneto', 'Vénétie', 'IT', 'region', 'it', 45.4415, 12.3155, 7, 'Carpaccio, risotto, polenta, tiramisu et ciabatta.'),
  (1, 'pt-minho', 'Minho', 'PT', 'region', 'pt', 41.6946, -8.3000, 8, 'Caldo verde, vinho verde et cuisine du nord du Portugal.'),
  (1, 'de-baden-wurttemberg', 'Bade-Wurtemberg', 'DE', 'region', 'de', 48.6616, 9.3501, 7, 'Souabe : spätzle, maultaschen et biscuits springerle.'),
  (1, 'ch-fribourg', 'Canton de Fribourg', 'CH', 'region', 'ch', 46.7000, 7.1000, 9, 'Gruyère, vacherin fribourgeois et fondue moitié-moitié.'),
  (1, 'be-flanders', 'Flandre', 'BE', 'region', 'be', 51.0000, 4.2000, 8, 'Carbonnade à la bière, waterzooi, frites et gaufres.'),
  (1, 'tr-gaziantep', 'Gaziantep', 'TR', 'city', 'tr', 37.0662, 37.3833, 11, 'Capitale de la pistache et du baklava, ville créative de l''UNESCO pour sa gastronomie.'),
  (1, 'ru-chechnya', 'Tchétchénie', 'RU', 'region', 'ru', 43.4023, 45.7187, 7, 'Cuisine vaïnakh : jijig-galnash (galettes et viande), fromages et herbes sauvages.'),
  (1, 'in-punjab', 'Pendjab', 'IN', 'region', 'in', 31.1471, 75.3412, 7, 'Tandoor, chana masala, aloo gobi, lassi et shikanjvi.'),
  (1, 'in-tamil-nadu', 'Tamil Nadu', 'IN', 'region', 'in', 11.1271, 78.6569, 7, 'Riz au citron, chutney coco, bondas et douceurs de temple.'),
  (1, 'in-kerala', 'Kerala', 'IN', 'region', 'in', 10.8505, 76.2711, 7, 'Appams, curry d''œufs, noix de coco, épices et fruits de mer.'),
  (1, 'in-maharashtra', 'Maharashtra', 'IN', 'region', 'in', 19.7515, 75.7139, 6, 'Poha, vada pav, misal et puran poli.'),
  (1, 'in-gujarat', 'Gujarat', 'IN', 'region', 'in', 22.2587, 71.1924, 6, 'Cuisine végétarienne sucrée-salée : dhokla, thepla et vedhmi.'),
  (1, 'in-west-bengal', 'Bengale-Occidental', 'IN', 'region', 'in', 22.9868, 87.8550, 7, 'Poissons à la moutarde, pommes de terre épicées et douceurs au lait.'),
  (1, 'in-telangana', 'Telangana', 'IN', 'region', 'in', 18.1124, 79.0193, 7, 'Cuisine du Deccan : biryani, haleem et piments.'),
  (1, 'cn-guangdong', 'Guangdong (Canton)', 'CN', 'region', 'cn', 23.3790, 113.7633, 7, 'Cuisine cantonaise : canard rôti, dim sum, congee et fruits de mer.'),
  (1, 'cn-shanghai', 'Shanghai', 'CN', 'city', 'cn', 31.2304, 121.4737, 10, 'Nouilles sautées, xiaolongbao et cuisine sucrée-salée du delta du Yangtsé.'),
  (1, 'tw-taichung', 'Taichung', 'TW', 'city', 'tw', 24.1477, 120.6736, 11, 'Ville où le bubble tea est né dans les années 1980.'),
  (1, 'my-selangor', 'Selangor', 'MY', 'region', 'my', 3.0738, 101.5183, 8, 'Bak kut teh de Klang, satay de Kajang et cuisine malaise.'),
  (1, 'id-central-java', 'Java central', 'ID', 'region', 'id', -7.1510, 110.1403, 7, 'Tempe mendoan, gudeg et cuisine javanaise sucrée.'),
  (1, 'ph-bicol', 'Bicol', 'PH', 'region', 'ph', 13.4210, 123.4137, 8, 'Lait de coco et piments : Bicol express et laing.'),
  (1, 'ng-south-west', 'Sud-Ouest (pays yoruba)', 'NG', 'region', 'ng', 7.5000, 4.2000, 7, 'Amala, ewedu, gbegiri, ekuru, asun et sauces au piment.'),
  (1, 'ng-south-east', 'Sud-Est (pays igbo)', 'NG', 'region', 'ng', 6.0000, 7.5000, 7, 'Soupes ofe (oha, achi), abacha, akamu et ukpo oka.'),
  (1, 'ng-south-south', 'Sud-Sud (delta du Niger)', 'NG', 'region', 'ng', 5.0000, 6.5000, 7, 'Soupes banga, afang, atama, owo et fruits de mer du delta.'),
  (1, 'ng-north', 'Nord du Nigeria', 'NG', 'region', 'ng', 11.5000, 8.5000, 6, 'Cuisine haoussa : tuwo, alkubus, suya et masa.'),
  (1, 'ng-benue', 'Bénoué', 'NG', 'region', 'ng', 7.3369, 8.7404, 7, 'Pays tiv : soupe ager, ignames et sorgho.'),
  (1, 'co-antioquia', 'Antioquia', 'CO', 'region', 'co', 7.1986, -75.3412, 7, 'Cuisine paisa : bandeja paisa, frijoles et arepas.'),
  (1, 'co-norte-de-santander', 'Norte de Santander', 'CO', 'region', 'co', 7.9463, -72.8988, 8, 'Cuisine frontalière : papa turmada, pastelitos et mute.'),
  (1, 'br-bahia', 'Bahia', 'BR', 'region', 'br', -12.5797, -41.7007, 6, 'Cuisine afro-brésilienne : moqueca, acarajé et huile de dendê.'),
  (1, 'ar-buenos-aires', 'Buenos Aires', 'AR', 'city', 'ar', -34.6037, -58.3816, 10, 'Parrillas, milanesa napolitana, dulce de leche et pizza porteña.'),
  (1, 'uy-punta-del-este', 'Punta del Este', 'UY', 'city', 'uruguay', -34.9667, -54.9500, 11, 'Station balnéaire où le chivito est né en 1946.'),
  (1, 've-caracas', 'Caracas', 'VE', 'city', 've', 10.4806, -66.9036, 11, 'Capitale des arepas, dont la reina pepiada créée en 1955.'),
  (1, 'pe-lima', 'Lima', 'PE', 'city', 'pe', -12.0464, -77.0428, 10, 'Capitale gastronomique : ceviche, cuisine nikkei et chifa.'),
  (1, 'jm-portland', 'Portland (Jamaïque)', 'JM', 'region', 'jm', 18.1000, -76.4500, 10, 'Boston Bay, berceau du jerk jamaïcain.'),
  (2, 'fr-marseille', 'Marseille', 'FR', 'city', 'fr-provence', 43.2965, 5.3698, 11, 'Port phocéen : bouillabaisse, tapenade, navettes et panisses.'),
  (2, 'fr-nice', 'Nice', 'FR', 'city', 'fr-provence', 43.7102, 7.2620, 11, 'Cuisine niçoise : ratatouille, socca, pissaladière et salade niçoise.'),
  (2, 'fr-lamotte-beuvron', 'Lamotte-Beuvron', 'FR', 'locality', 'fr-centre-val-de-loire', 47.6018, 2.0270, 12, 'Village de Sologne où les sœurs Tatin ont rendu célèbre leur tarte renversée.'),
  (2, 'fr-paris', 'Paris', 'FR', 'city', 'fr-ile-de-france', 48.8566, 2.3522, 11, 'Croque-monsieur, soupe à l''oignon des Halles, éclairs et mille-feuilles.'),
  (2, 'fr-nantes', 'Nantes', 'FR', 'city', 'fr-pays-de-la-loire', 47.2184, -1.5536, 11, 'Berceau du beurre blanc, servi avec les poissons de Loire.'),
  (2, 'gb-liverpool', 'Liverpool', 'GB', 'city', 'gb-england', 53.4084, -2.9916, 11, 'Scouse, le ragoût des marins qui a donné son surnom aux habitants.'),
  (2, 'gb-shrewsbury', 'Shrewsbury', 'GB', 'city', 'gb-england', 52.7073, -2.7553, 12, 'Ville du Shropshire célèbre pour ses biscuits au beurre depuis le XVIIᵉ siècle.'),
  (2, 'us-san-antonio', 'San Antonio', 'US', 'city', 'us-texas', 29.4241, -98.4936, 10, 'Berceau des « chili queens » et du chili con carne.'),
  (2, 'us-boston', 'Boston', 'US', 'city', 'us-massachusetts', 42.3601, -71.0589, 11, '« Beantown » : fèves au lard à la mélasse et cuisine de la mer.'),
  (2, 'us-san-francisco', 'San Francisco', 'US', 'city', 'us-california', 37.7749, -122.4194, 11, 'Cioppino des pêcheurs italiens, pain au levain et Chinatown.'),
  (2, 'us-los-angeles', 'Los Angeles', 'US', 'city', 'us-california', 34.0522, -118.2437, 10, 'Sandwich French dip, Orange Julius et street food multiculturelle.'),
  (2, 'us-buffalo', 'Buffalo', 'US', 'city', 'us-new-york', 42.8864, -78.8784, 11, 'Berceau des ailes de poulet épicées (Buffalo wings), 1964.'),
  (2, 'us-philadelphia', 'Philadelphie', 'US', 'city', 'us-pennsylvania', 39.9526, -75.1652, 11, 'Cheesesteak, pretzels mous et bonbons « Irish potatoes ».'),
  (2, 'us-latrobe', 'Latrobe', 'US', 'city', 'us-pennsylvania', 40.3212, -79.3795, 12, 'Petite ville où le banana split est né en 1904.'),
  (2, 'mx-tijuana', 'Tijuana', 'MX', 'city', 'mx-baja-california', 32.5149, -117.0382, 11, 'Où Caesar Cardini a inventé la salade César en 1924.'),
  (2, 'it-rome', 'Rome', 'IT', 'city', 'it-lazio', 41.9028, 12.4964, 11, 'Carbonara, fettuccine Alfredo, supplì et artichauts à la juive.'),
  (2, 'in-thiruvaiyaru', 'Thiruvaiyaru', 'IN', 'locality', 'in-tamil-nadu', 10.8800, 79.1000, 12, 'Ville du delta de la Kaveri, berceau de l''Ashoka halwa.'),
  (2, 'in-hyderabad', 'Hyderabad', 'IN', 'city', 'in-telangana', 17.3850, 78.4867, 11, 'Capitale du biryani dum et du haleem.'),
  (2, 'my-klang', 'Klang', 'MY', 'city', 'my-selangor', 3.0449, 101.4456, 11, 'Capitale revendiquée du bak kut teh.'),
  (2, 'ng-ibadan', 'Ibadan', 'NG', 'city', 'ng-south-west', 7.3775, 3.9470, 11, 'Capitale de l''abula (amala, gbegiri et ewedu).'),
  (2, 'ng-calabar', 'Calabar', 'NG', 'city', 'ng-south-south', 4.9757, 8.3417, 11, 'Cuisine efik réputée : afang, atama et otong.'),
  (2, 'co-cucuta', 'Cúcuta', 'CO', 'city', 'co-norte-de-santander', 7.8939, -72.5078, 11, 'Ville natale de la papa turmada.')
),
level_one as (
  insert into public.culinary_places (slug, name, country_code, place_type, parent_id, latitude, longitude, default_zoom, summary)
  select n.slug, n.name, n.country_code, n.place_type, p.id, n.latitude, n.longitude, n.default_zoom, n.summary
  from new_places n
  join public.culinary_places p on p.slug = n.parent_slug
  where n.depth = 1
  on conflict (slug) do nothing
  returning id, slug
)
insert into public.culinary_places (slug, name, country_code, place_type, parent_id, latitude, longitude, default_zoom, summary)
select n.slug, n.name, n.country_code, n.place_type, coalesce(l.id, p.id), n.latitude, n.longitude, n.default_zoom, n.summary
from new_places n
left join level_one l on l.slug = n.parent_slug
left join public.culinary_places p on p.slug = n.parent_slug
where n.depth = 2 and coalesce(l.id, p.id) is not null
on conflict (slug) do nothing;

-- Londres et la Cornouailles sont en Angleterre
update public.culinary_places c
set parent_id = e.id
from public.culinary_places e
where e.slug = 'gb-england' and c.slug in ('londres', 'cornouailles');

-- Correspondance recette → lieu (null = classique sans frontières).
-- Limitée aux recettes éditoriales importées : les titres étaient uniques au
-- moment de l'application, mais une recette de la communauté pourrait porter
-- le même nom.
create temporary table recipe_geo_fix (title text primary key, place_slug text) on commit drop;

insert into recipe_geo_fix (title, place_slug) values
  -- France
  ('Bouillabaisse', 'fr-marseille'),
  ('Tapenade', 'fr-marseille'),
  ('Ratatouille provençale', 'fr-nice'),
  ('Tartiflette', 'fr-savoie'),
  ('Tarte Tatin', 'fr-lamotte-beuvron'),
  ('Croque Monsieur', 'fr-paris'),
  ('Onion Soup', 'fr-paris'),
  ('Lemon Mille-feuille', 'fr-paris'),
  ('Beurre Blanc', 'fr-nantes'),
  ('Crêpes I', 'fr-bretagne'),
  ('Ham and Cheese Crepes', 'fr-bretagne'),
  ('Crème Anglaise', 'fr'),
  ('Velouté Sauce', 'fr'),
  ('Eclairs', 'fr'),
  ('Cream Puff', 'fr'),
  ('Cherries Jubilee', 'fr'),
  ('Tartar Sauce', 'fr'),
  ('Cheese Sauce I', 'fr'),
  ('Au Jus Sandwich', 'us-los-angeles'),
  ('Chip Butty', 'gb-england'),
  ('Jambalaya I', 'us-new-orleans'),
  ('Orange French Toast', null),
  ('Cheese Spread on French Bread', null),
  -- Royaume-Uni / Irlande
  ('Haggis', 'gb-scotland'),
  ('Tattie Scones', 'gb-scotland'),
  ('Shortbread', 'gb-scotland'),
  ('Plain Scones', 'gb-scotland'),
  ('Liverpool Lamb and Vegetable Soup (Scouse)', 'gb-liverpool'),
  ('Shrewsbury Cakes', 'gb-shrewsbury'),
  ('Stargazy Pie', 'cornouailles'),
  ('Beef Pasties', 'cornouailles'),
  ('Coronation Chicken', 'londres'),
  ('Eggs Connaught', 'londres'),
  ('Banoffee Pie', 'gb-england'),
  ('Brandy Butter', 'royaume-uni'),
  ('Mince Pie with Meat I', 'royaume-uni'),
  ('Mincemeat', 'royaume-uni'),
  ('Steak and Kidney Pudding', 'royaume-uni'),
  ('Lemon Drizzle Cake', 'royaume-uni'),
  ('Coconut Pyramids', 'royaume-uni'),
  ('Cheese on Toast', 'royaume-uni'),
  ('Crispy Roast Potatoes', 'royaume-uni'),
  ('Apple Jelly', 'royaume-uni'),
  ('Banana Cream I', 'royaume-uni'),
  ('Banana Cream II', 'royaume-uni'),
  ('Coconut Biscuits', 'royaume-uni'),
  ('Fruit Crumble', 'royaume-uni'),
  ('Bread Pudding', 'royaume-uni'),
  ('Coddle', 'ie-dublin'),
  ('Irish Potatoes', 'us-philadelphia'),
  -- États-Unis
  ('Jambalaya II', 'us-new-orleans'),
  ('Po'' Boy', 'us-new-orleans'),
  ('Cajun Red Beans and Rice', 'us-new-orleans'),
  ('Seafood Gumbo', 'us-louisiana'),
  ('Crawfish Boil', 'us-louisiana'),
  ('Cajun Burger', 'us-louisiana'),
  ('Chili con carne style Texas', 'us-san-antonio'),
  ('Original Texas-Style Chili', 'us-san-antonio'),
  ('Frito Pie (Baked)', 'us-texas'),
  ('Frito Pie Chili', 'us-texas'),
  ('Chicken-fried Steak', 'us-texas'),
  ('Beef Fajitas', 'us-texas'),
  ('Chicken Fajitas', 'us-texas'),
  ('Jalapeno Sausage and Bacon Appetizers (Atomic Buffalo Turds)', 'us-texas'),
  ('Chili Powder II', 'us-texas'),
  ('Barbecue Beef Brisket Sandwiches', 'us-texas'),
  ('Taco Salad', 'us-texas'),
  ('Boston Baked Beans', 'us-boston'),
  ('Chocolate Chip Cookies I', 'us-massachusetts'),
  ('Chocolate Chip Cookies II', 'us-massachusetts'),
  ('Chocolate Chip Cookies III', 'us-massachusetts'),
  ('Chocolate Chip Cookies (Vegan)', 'us-massachusetts'),
  ('Chocolate Chip Cookies (Gluten-Free)', 'us-massachusetts'),
  ('Crab Cakes', 'us-maryland'),
  ('Crab Dip', 'us-maryland'),
  ('Buckeyes', 'us-ohio'),
  ('Hashbrown Casserole', 'us-utah'),
  ('Frog''s Eye Salad', 'us-utah'),
  ('Ozark Pudding', 'us-ozarks'),
  ('Henry Thiele''s Pancake', 'us-oregon'),
  ('Plank-Grilled Salmon', 'us-washington'),
  ('Acorn Crusted Salmon', 'us-washington'),
  ('Cioppino (Italian Seafood Stew)', 'us-san-francisco'),
  ('California Curry Chicken', 'us-california'),
  ('Orange Julius', 'us-los-angeles'),
  ('Spicy Fried Wings', 'us-buffalo'),
  ('Clam Dip', 'us-new-york'),
  ('Banana Split I', 'us-latrobe'),
  ('Banana Split II', 'us-latrobe'),
  ('Biscuits and Gravy', 'us-south'),
  ('Braised Collard Greens', 'us-south'),
  ('Banana Pudding', 'us-south'),
  ('Candied Sweet Potatoes', 'us-south'),
  ('Candied Yams', 'us-south'),
  ('Country Fried Chicken', 'us-south'),
  ('Ambrosia Fruit Salad', 'us-south'),
  ('Chess Pie', 'us-south'),
  ('Apple Cobbler', 'us-south'),
  ('Poppyseed Chicken', 'us-south'),
  ('Cream Cheese Mints', 'us-south'),
  ('Breakfast Burrito', 'us-new-mexico'),
  ('Fry Bread I', 'us-arizona'),
  ('Fry Bread II', 'us-arizona'),
  ('Haupia (Hawaiian Coconut Pudding)', 'us-hawaii'),
  ('Italian Dressing I', 'us'),
  ('Italian Dressing II', 'us'),
  ('Italian Seasoning', 'us'),
  ('Hamburger Deluxe', 'us'),
  ('Beef and Mushroom Burger', 'us'),
  ('Chili (Vegan)', 'us'),
  ('Chipotle Chili', 'us'),
  ('Ants on a Log', 'us'),
  ('Apple Pie I', 'us'),
  ('Apple Pie II', 'us'),
  ('Banana Cream Pie I', 'us'),
  ('Baby Back Ribs', 'us'),
  ('Backyard BBQ Chicken', 'us'),
  ('Barbecue Ribs', 'us'),
  ('Barbecue Wings', 'us'),
  ('Barbecue Sauce (Sweet)', 'us'),
  ('Barbecue Sauce I', 'us'),
  ('Beef Jerky', 'us'),
  ('Beef Stew I', 'us'),
  ('Broccoli Salad', 'us'),
  ('Chipped Beef on Toast', 'us'),
  ('Chocolate Chip Pumpkin Cookies', 'us'),
  ('Oreo Pie', 'us'),
  ('Oreo Milkshake', 'us'),
  ('Spinach Artichoke Dip', 'us'),
  ('Classic Pot Roast', 'us'),
  ('Fudge Brownies', 'us'),
  ('Cake Brownies', 'us'),
  ('Chicken Alfredo', 'us'),
  ('Bolognese Sauce', 'us'),
  ('Eggnog', 'us'),
  ('Campfire Banana Boat', 'us'),
  ('Applewood Bacon', 'us'),
  ('Bourbon Apples', 'us'),
  ('Popcorn', 'us'),
  -- Canada / Mexique / Amérique latine
  ('Vancouver Cheesecake', 'ca-vancouver'),
  ('Caesar Salad', 'mx-tijuana'),
  ('Pozole rojo mexicain au porc', 'mx-jalisco'),
  ('Adobo Sauce', 'mx'),
  ('Chili Colorado', 'mx'),
  ('Cheese Enchilada', 'mx'),
  ('Spicy Hot Salsa', 'mx'),
  ('Bandeja paisa colombienne', 'co-antioquia'),
  ('Frijoles Antioqueños (Colombian Bean Stew)', 'co-antioquia'),
  ('Potato and Sausage Casserole (Papa Turmada)', 'co-cucuta'),
  ('Moqueca baiana de poisson', 'br-bahia'),
  ('Milanesa napolitana argentine', 'ar-buenos-aires'),
  ('Chivito uruguayen au bœuf, jambon et mozzarella', 'uy-punta-del-este'),
  ('Arepas reina pepiada vénézuéliennes', 've-caracas'),
  ('Acevichada Sauce', 'pe-lima'),
  ('Jamaican Jerk Chicken', 'jm-portland'),
  ('Poulet jerk jamaïcain', 'jm-portland'),
  -- Europe
  ('Arancini (Italian Fried Rice Balls)', 'it-sicilia'),
  ('Cannoli', 'it-sicilia'),
  ('Caponata (Sicilian Eggplant and Vegetables)', 'it-sicilia'),
  ('Carbonara Pasta', 'it-rome'),
  ('Spaghetti alla carbonara', 'it-rome'),
  ('Alfredo Sauce', 'it-rome'),
  ('Ossobuco Alla Milanese', 'it-milan'),
  ('Balsamic Dressing', 'it-emilia-romagna'),
  ('Tagliatelle Bake', 'it-emilia-romagna'),
  ('Beef Carpaccio I', 'it-veneto'),
  ('Ciabatta', 'it-veneto'),
  ('Venetian Soup', 'it-veneto'),
  ('Limoncello', 'it-campania'),
  ('Caprese Salad', 'it-campania'),
  ('Calzone', 'it-naples'),
  ('Spinach and Ricotta Gnocchi', 'it'),
  ('Paella Valenciana', 'es-valencia'),
  ('Arroz Negro (Valencian Squid Rice)', 'es-valenciana'),
  ('Valencian-Inspired Paella', 'es-valenciana'),
  ('Paella de Marisco', 'es-valenciana'),
  ('Paella Roja', 'es-valenciana'),
  ('Churros II', 'es'),
  ('Caldo verde portugais', 'pt-minho'),
  ('Springerle', 'de-baden-wurttemberg'),
  ('Vanillekipferl (Almond Crescent Cookies)', 'at-vienna'),
  ('Fondue suisse moitié-moitié', 'ch-fribourg'),
  ('Carbonnade flamande', 'be-flanders'),
  ('Chicken Gyros', 'gr'),
  ('Cirdingis (Chechen Meat and Dumplings)', 'ru-chechnya'),
  -- Moyen-Orient
  ('Baklava with Pistachio Nuts', 'tr-gaziantep'),
  ('Baklava', 'tr'),
  ('Baba Ganoush', 'lb'),
  ('Tabbouleh I', 'lb'),
  ('Taboon Bread', 'ps'),
  -- Asie
  ('Tandoori Masala', 'in-punjab'),
  ('Shikanjvi (Punjabi Spiced Lemonade)', 'in-punjab'),
  ('Chana masala indien', 'in-punjab'),
  ('Gajjar Halwa (Carrot Pudding)', 'in-punjab'),
  ('Potato and Cauliflower Curry (Aloo Gobi)', 'in-punjab'),
  ('Tandoori Tofu', 'in-punjab'),
  ('Appam (Fermented Rice Pancake)', 'in-kerala'),
  ('Egg Roast', 'in-kerala'),
  ('Ashoka Halwa (Mung Bean Pudding)', 'in-thiruvaiyaru'),
  ('Coconut Chutney (South Indian)', 'in-tamil-nadu'),
  ('Lemon Rice', 'in-tamil-nadu'),
  ('Bonda (South Indian Vegetable Fritter)', 'in-tamil-nadu'),
  ('Coconut Rice (Indian)', 'in-tamil-nadu'),
  ('Pohe (Spiced Flattened Rice)', 'in-maharashtra'),
  ('Vedhmi (Sweet Stuffed Flatbread)', 'in-gujarat'),
  ('Bengal Potatoes', 'in-west-bengal'),
  ('Biryani', 'in-hyderabad'),
  ('Spinach Pakoras', 'in'),
  ('Onion Pakoras', 'in'),
  ('Bhuna Khichuri (Bengali Rice and Lentils)', 'bd'),
  ('Cantonese Crispy Fried Chicken', 'cn-guangdong'),
  ('Cantonese Roast Duck', 'cn-guangdong'),
  ('Shark Fin Soup', 'cn-guangdong'),
  ('Sesame Shrimp Toast', 'cn-guangdong'),
  ('Chili Oil', 'cn-sichuan'),
  ('Pan-Fried Shanghai Noodles', 'cn-shanghai'),
  ('Pork Gyoza', 'jp'),
  ('Seaweed Salad', 'jp'),
  ('Bubble Tea', 'tw-taichung'),
  ('Pork Spare Rib Soup (Bah Kut Teh)', 'my-klang'),
  ('Tempe Mendoan I', 'id-central-java'),
  ('Tempe Mendoan II', 'id-central-java'),
  ('Bicol Express', 'ph-bicol'),
  -- Afrique
  ('Cocoyam Fufu', 'gh'),
  ('Ata Ekuru (Ekuru Sauce)', 'ng-south-west'),
  ('Ekuru (White Bean Pudding)', 'ng-south-west'),
  ('Aadun (Nigerian Corn Flour with Palm Oil)', 'ng-south-west'),
  ('Adalu (Bean and Corn Porridge)', 'ng-south-west'),
  ('Asun (Goat in Pepper Sauce)', 'ng-south-west'),
  ('Abula (Nigerian Three Stews)', 'ng-ibadan'),
  ('Achi Soup', 'ng-south-east'),
  ('Ora Soup I', 'ng-south-east'),
  ('African Salad I', 'ng-south-east'),
  ('Akamu (Nigerian Pudding)', 'ng-south-east'),
  ('Ukpo Oka (Nigerian Corn Pudding)', 'ng-south-east'),
  ('Afang Soup', 'ng-calabar'),
  ('Atama Soup', 'ng-calabar'),
  ('Otong Soup', 'ng-calabar'),
  ('Banga Soup', 'ng-south-south'),
  ('Banga Rice', 'ng-south-south'),
  ('Owo Soup', 'ng-south-south'),
  ('Alkubus (Nigerian Steamed Bread)', 'ng-north'),
  ('Tuwon Dawa (Nigerian Sorghum Swallow)', 'ng-north'),
  ('Ager Soup', 'ng-benue'),
  -- Recettes mal classées sans origine précise → classiques sans frontières
  ('Almond Milk II', null),
  ('Baked Eggplant', null),
  ('Chicken Barbecue Sauce', null),
  ('Veggie Salad', null),
  ('Asian Grilled Duck Breasts', null),
  ('Asian Grilled Salmon', null),
  ('Banana Curry', null),
  ('Beef Stir-Fry', null),
  ('Chicken Fried Rice', null),
  ('Chickpea Stew', null),
  ('Chipotle Dip', null),
  ('Chipotle Fried Chicken', null),
  ('Chipotle Ketchup', null),
  ('Eggplant Pasta', null),
  ('Potato Castle', null),
  ('Seafood Fried Rice', null),
  ('Seafood Pizza', null),
  ('Spicy Black Beans', null),
  ('Spicy Cheddar Dip with Olives', null),
  ('Spicy Chilli Chicken', null),
  ('Spicy Fried Rice', null),
  ('Spicy Garlic Oil', null),
  ('Vegetable Spring Roll', null);

do $$
declare missing text;
begin
  select string_agg(f.place_slug, ', ') into missing
  from recipe_geo_fix f
  where f.place_slug is not null
    and not exists (select 1 from public.culinary_places p where p.slug = f.place_slug);
  if missing is not null then
    raise exception 'Lieux introuvables : %', missing;
  end if;
end $$;

-- Application : pays, région texte et lieu principal
update public.recipes r
set country_code = p.country_code,
    region = case when p.place_type = 'country' then null
                  when parent.place_type = 'country' or parent.id is null then p.name
                  else parent.name end,
    primary_place_id = p.id,
    is_borderless = false
from recipe_geo_fix f
join public.culinary_places p on p.slug = f.place_slug
left join public.culinary_places parent on parent.id = p.parent_id
where r.title = f.title and r.is_editorial and f.place_slug is not null;

update public.recipes r
set country_code = null,
    region = null,
    primary_place_id = null
from recipe_geo_fix f
where r.title = f.title and r.is_editorial and f.place_slug is null;

-- Recette contenant du cannabis : retirée de la publication (réversible)
update public.recipes set status = 'archived' where title = 'Cannabutter' and is_editorial;

-- Tout ce qui reste sans pays devient un classique sans frontières
update public.recipes
set is_borderless = true
where is_editorial and country_code is null and primary_place_id is null;

-- Champ région qui répétait simplement le nom du pays
update public.recipes r
set region = null
from public.culinary_places p
where p.id = r.primary_place_id
  and p.place_type = 'country'
  and r.region is not null
  and lower(r.region) = lower(p.name);

-- Synchronisation de recipe_locations avec primary_place_id
delete from public.recipe_locations l
using public.recipes r
where l.recipe_id = r.id
  and l.is_primary
  and l.place_id is distinct from r.primary_place_id;

insert into public.recipe_locations (recipe_id, place_id, relation, is_primary)
select r.id, r.primary_place_id, 'origin', true
from public.recipes r
where r.primary_place_id is not null
on conflict (recipe_id, place_id) do update set is_primary = true, relation = 'origin';

-- Spécialités de lieu pour les recettes régionales ou locales (visibles en zoomant sur le globe)
insert into public.place_specialties (place_id, recipe_id, name, description, origin_note, is_signature, sort_order)
select r.primary_place_id, r.id, coalesce(t.title, r.title), null, 'Spécialité de ' || p.name, true, 50
from public.recipes r
join public.culinary_places p on p.id = r.primary_place_id
left join public.recipe_title_translations t on t.recipe_id = r.id and t.language_code = 'fr'
where p.place_type <> 'country'
  and r.status = 'published'
  and not exists (
    select 1 from public.place_specialties s
    where s.place_id = r.primary_place_id and s.recipe_id = r.id
  );
