open Netlist_ast
open Graph

exception Combinational_cycle

let  read_exp qq = 
  match qq with 
  |i,eq -> 
    let rec read_arg a = 
      match a with
      |Avar r -> [r]
      |_ -> [] in

    match eq with 
    |Earg a -> read_arg a
    |Ereg e -> []
    |Ebinop (g,a,z) -> (read_arg a)@(read_arg z)
    |Emux (a,aa,aaa) -> (read_arg a)@(read_arg aa)@(read_arg aaa)
    |Erom (_,_,a) -> read_arg a
    |Eram (_,_,a,aa,aaa,aaaa) -> (read_arg a)
    |Econcat (a,z) -> (read_arg a)@(read_arg z)
    |Eslice (_,_,a) -> (read_arg a)
    |Eselect (_,a) -> (read_arg a)
    |Enot a -> (read_arg a)

let schedule p = 
  let g = mk_graph () in
  
  let temp v i= 
    try (add_edge g v i) with |Not_found -> (*(add_node g v);(add_edge g i v);*) failwith "Houston we've got a problem" in (*add_node g i : add_node g v*)

  let rec get_all_eq l =
    match  l with 
    |[] -> []
    |(i,_)::q -> i::(get_all_eq q) in
    
  let rec doing2 l = 
    match l with 
    |[] -> ()
    |t::q -> add_node g t; doing2 q in

  doing2 p.p_inputs;
  doing2 (get_all_eq p.p_eqs);


  let rec aux l = 
    match l with 
    |[] -> ()
    |(i,eq)::q -> List.iter (fun v -> temp v i) (read_exp (i,eq)); aux q in
  aux p.p_eqs;

  try (
  let s_sort = topological g in
  let rec get_all_eq l =
    match  l with 
    |[] -> []
    |(i,_)::q -> i::(get_all_eq q) in

    
  let all_eq = get_all_eq p.p_eqs in

    let rec trouv x l = 
      match l with 
      |[] -> failwith "Impossible en théorie"
      |(i,eq)::q when (i=x) -> (i,eq)
      |t::q -> trouv x q in

  let rec fct l =
    match l with 
    |[] -> []
    |t::q when (List.mem t all_eq) -> (trouv t p.p_eqs)::(fct q)
    |t::q -> fct q in

  {p_eqs = fct s_sort; p_inputs = p.p_inputs; p_outputs = p.p_outputs; p_vars = p.p_vars};
  

  
  
  
  ) with |Cycle -> raise Combinational_cycle
    
  

