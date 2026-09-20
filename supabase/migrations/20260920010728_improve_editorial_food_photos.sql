update public.recipe_images
set
  external_url='https://upload.wikimedia.org/wikipedia/commons/a/a3/Eq_it-na_pizza-margherita_sep2005_sml.jpg',
  source_page_url='https://commons.wikimedia.org/wiki/File:Eq_it-na_pizza-margherita_sep2005_sml.jpg',
  photographer_name='Valerio Capello',
  photographer_url='https://en.wikipedia.org/wiki/User:ElfQrin',
  license_name='CC BY-SA 3.0',
  license_url='https://creativecommons.org/licenses/by-sa/3.0/',
  attribution_text='Photo : Valerio Capello · Wikimedia Commons · CC BY-SA 3.0',
  alt_text='Pizza Margherita napolitaine photographiée à Naples'
where recipe_id='10000000-0000-4000-8000-000000000001'
  and source_type='external_licensed';

update public.recipe_images
set
  external_url='https://upload.wikimedia.org/wikipedia/commons/6/6c/Khao_soi_Chiang_Mai.jpg',
  source_page_url='https://commons.wikimedia.org/wiki/File:Khao_soi_Chiang_Mai.jpg',
  photographer_name='Takeaway',
  photographer_url='https://commons.wikimedia.org/wiki/User:Takeaway',
  license_name='CC BY-SA 3.0',
  license_url='https://creativecommons.org/licenses/by-sa/3.0/',
  attribution_text='Photo : Takeaway · Wikimedia Commons · CC BY-SA 3.0',
  alt_text='Khao soi au poulet photographié à Chiang Mai'
where recipe_id='10000000-0000-4000-8000-000000000004'
  and source_type='external_licensed';