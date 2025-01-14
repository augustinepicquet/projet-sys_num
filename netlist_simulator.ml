open Netlist_ast
exception NetlistError of string
let debug = false
let cases_memoire = true
let print_only = ref false
let number_steps = ref (-1)
let activate_c = ref false
let rom_path = "rom.ck"
let ram_path = "ram.ck"
let ram_size = 65536
type ops = |VarAssign of (ident*string)
           |VarDeclare of (ident)
           |For of int
           |RegUpgradeEndCycle of ident
           |IntMain
           |Jump
           |PrintVar of (ident*int)
           |InputVar of (ident*int)
           |TrucEnTrop of (string)

exception InputProblem
(*Nom interdit pour les variables cpt_0123456789, number_steps, ram_data, size_0123456789, rom_data*)
let write_c program  number_steps path = 


  let action = ref [IntMain] in 
  let code = ref "#include <stdio.h> \n#include <stdbool.h>\n#include <stdlib.h>\n#include <string.h>\n\n#define RAM_PATH \"ram.ck\"\n#define ROM_PATH \"rom.ck\"\n\n" in
  
  code := !code ^ ("void printBoolArray(unsigned long long value, unsigned long long cpt_0123456789, const char *ident) {\n\
  printf(\"%s = \",ident);
   for (unsigned long long i = cpt_0123456789-1; i >= 0; i--) {\n\
   printf(\"%llu\",(value >> i) & 1); \n\
   }\n\
   printf(\"\\n\");\n\
  }\n\n");


  code := !code ^ ("unsigned long long binary_to_int(const char *bin_str) {\n\
   return (unsigned long long) strtol(bin_str, NULL, 2); \n\
   }\n\
   \n\
   unsigned long long read_binary(unsigned long long size_0123456789,const char *ident) {\n\
   char input[64];  \n\
   \n\
   while (1) {\n\
       printf(\"%s ? (%llu bits) : \", ident,size_0123456789);\n\
       scanf(\"%s\", input);  \n\
       if (strlen(input) == size_0123456789) {\n\
       int all_good = 1;\n\
           for (unsigned long long i = 0; i < size_0123456789; i++) {\n\
               if (input[i] != '0' && input[i] != '1') {\n\
                   all_good = 0;\n\
                   break;\n\
               }\n\
           }\n\
           if (all_good) {\n\
            \n
               return binary_to_int(input); \n\
           }\n\
       }\n\
       printf(\"Wrong input :(\\n\");\n\
   }\n\
   }\n\n");




code := !code ^ "void load_rom(char *ram_data, size_t size) {\n\
    FILE *file = fopen(ROM_PATH, \"r\"); \n\
    if (file == NULL) {\n\
        exit(1);  \n\
    }\n\
\n\
    size_t i = 0;\n\
    char c;\n\
    while (i < size && (c = fgetc(file)) != EOF) {\n\
        if (c == '0' || c == '1') {\n\
            ram_data[i++] = c;  \n\
        }\n\
    }\n\
\n\
    ram_data[i] = '\\0';  \n\
\n\
    fclose(file);\n\
}\n";




code := !code ^ "\nunsigned long long read_rom(const char *rom, unsigned long long i, unsigned long long j) {
    unsigned long long result = 0;
    for (unsigned long long index = i; index < j; ++index) {
        result <<= 1;
        if (rom[index] == '1') {
            result |= 1;
        }
    }
    return result;
}\n\n";







  (*let ram_str = "size_t SIZE_RAM = "^(string_of_int ram_size)^";\nchar ram_data[SIZE_RAM + 1];\n" in*)
  let rom_str = "size_t SIZE_RAM = "^(string_of_int ram_size)^";\n"^"char rom_data[SIZE_RAM + 1];\n\n" in
  action := !action @  [TrucEnTrop rom_str];



  let p = Scheduler.schedule program in

  let list_keys env =
    Env.fold (fun key _ acc -> key :: acc) env [] in
  
  let name = Hashtbl.create 1 in
  (*Cette fonction ajoute aussi à la liste d'action la déclaration des variables (enfait maintenant elle ne sert plus qu'a ca)*)
  let rec give_name l i = 
    match l with 
    |[] -> ()
    |t::q -> Hashtbl.replace name t t (*("var_"^(string_of_int i))*);  action := (!action) @ [VarDeclare t];give_name q (i+1); in
  give_name (list_keys p.p_vars) 0;
  
  let load_rom = "load_rom(rom_data,SIZE_RAM); \n\n" in
  action := !action @ [TrucEnTrop load_rom];

  action := (!action) @ [For number_steps;Jump];
  
  (*let load_ram = "load_ram(ram_data,SIZE_RAM); \n" in*)



  (*Si on a une var x et une var x_reg_version (peu probable) ou x_cpt_ ça pose de gros soucis*)
  (*Tous est représenté par des entiers mais seule les n premiers bits comptent (1 pour les VBit)*)
  (*Pour le mux, pour le choice, la seul chose qui compte c'est que le bit de poids faible soit 0 ou 1*)
  let get_string_declaration x = 
    match (Env.find x p.p_vars) with 
    |TBit -> "unsigned long long "^(Hashtbl.find name x)^";\nunsigned long long "^(Hashtbl.find name x)^"_reg_version = 0;\n"
    |TBitArray n -> "unsigned long long "^(Hashtbl.find name x)^";\n" ^ "unsigned long long "^(Hashtbl.find name x)^"_reg_version = 0;\n" in

    let v_to_int v =
      match v with
      |VBit b -> if b then 1 else 0
      |VBitArray arr -> Array.fold_left (let f acc b = (acc lsl 1) + if b then 1 else 0 in f) 0 arr in

  let arg_to_s arg = match arg with 
      |Avar y -> (Hashtbl.find name y)
      |Aconst v -> string_of_int (v_to_int v) in

  let arg_to_taille arg = match arg with 
      |Avar y -> (match (Env.find y p.p_vars) with |TBitArray n -> n |_ -> 1)
      |Aconst v -> (match (v) with |VBitArray tab -> Array.length tab |_ -> 1) in


  let rec action_input l = 
    match l with 
    |[] -> ()
    |t::q -> action := !action @ [InputVar (t,(match (Env.find t p.p_vars) with |TBitArray n -> n |_ -> 1))]; action_input q in

  action_input (p.p_inputs);
  
  let ram_delay = ref [] in 
  let cpt_ram = ref 0 in



  let get_string_equ equ =
    match equ with
    | (x, Earg argu) -> (match argu with 
                      |Avar y -> action := !action @ [VarAssign (x, ((Hashtbl.find name y)^";\n"))]
                      |Aconst v -> action := !action @ [VarAssign (x, ((string_of_int (v_to_int v))^";\n"))])
        
    | (x, Ereg y) -> action := !action @ [VarAssign (x,((Hashtbl.find name y)^"_reg_version;\n"))] 
        
    | (x, Enot argu) -> (match argu with
                      |Avar y -> action := !action @ [VarAssign (x, ("~"^(Hashtbl.find name y)^";\n"))]
                      |Aconst v -> action := !action @ [VarAssign (x, ("~"^(string_of_int (v_to_int v))^";\n"))])

    | (x, Ebinop (op, a1, a2)) -> let val_b = 
                      (match op with 
                      |Nand -> "~ ("^(arg_to_s a1)^" & "^(arg_to_s a2)^");\n"
                      |Or -> "("^(arg_to_s a1)^" | "^(arg_to_s a2)^");\n"
                      |And -> "("^(arg_to_s a1)^" & "^(arg_to_s a2)^");\n"
                      |Xor -> "("^(arg_to_s a1)^" ^ "^(arg_to_s a2)^");\n") in
                      action := !action @ [VarAssign (x,val_b)]
        
    | (x, Emux (a, b, c)) -> let val_b =  "("^(arg_to_s a)^"&1) ? "^(arg_to_s c)^" : "^(arg_to_s b)^";\n" in
                              action := !action @ [VarAssign (x,val_b)]
        
    | (x, Econcat (a, b)) ->let size_b = string_of_int (arg_to_taille b) in
                            let size_a = string_of_int (arg_to_taille a) in
                            let val_b = "("^"("^(arg_to_s a)^" & ((1ULL << "^size_a^") - 1)"^") << "^size_b^") | ("^(arg_to_s b)^" & ((1ULL << "^size_b^") - 1));\n" in
                            action  := !action @ [VarAssign (x,val_b)]
        
    | (x, Eselect (i, a)) -> let val_b = "("^(arg_to_s a)^" >> ("^(string_of_int (arg_to_taille a))^"-"^(string_of_int i)^" - 1)) & 1;\n" in
                            action := !action @ [VarAssign (x,val_b)]
        
    | (x, Eslice (i, j, a)) -> let val_b = "("^(arg_to_s a)^" >> ("^(string_of_int (arg_to_taille a))^"-"^(string_of_int j)^"-1)) & ((1ULL << ("^(string_of_int j)^" - "^(string_of_int i)^" + 1)) - 1);\n" in
                              action := !action @ [VarAssign (x,val_b)]
                
    | (x, Eram (addr_size, word_size, read_addr, write_enable, write_addr, write_data)) -> 
                                let name  = "tableau_ram"^(string_of_int !cpt_ram) in
                                cpt_ram := !cpt_ram + 1;
                                (*let start_pos = "("^(arg_to_s read_addr)^" * "^(string_of_int word_size)^")" in
                                let val_b = "(read_ram(ram_data,"^(start_pos)^","^start_pos^"+"^(string_of_int (word_size))^"));\n" in*) (*Héritage d'une époque éteinte*)
                                let val_b = name^"["^(arg_to_s read_addr)^"];\n" in 
                                action := !action @ [VarAssign (x,val_b)];
                                ram_delay := (addr_size, word_size, write_enable, write_addr, write_data, name)::(!ram_delay)

    | (x, Erom (addr_size, word_size, read_addr)) ->  
                                let start_pos = "("^(arg_to_s read_addr)^" * "^(string_of_int word_size)^")" in
                                let val_b = "(read_rom(rom_data,"^(start_pos)^","^start_pos^"+"^(string_of_int (word_size))^"));\n" in
                                action := !action @ [VarAssign (x,val_b)] in

  List.iter get_string_equ p.p_eqs;
  
  let decl_ram = ref "" in
  


  let rec add_action_write_ram l =
    match l with 
    |[] -> ()
    |(addr_size,word_size,we,write_addr,write_data,name)::q -> 
              (*le nom du tableau est donne quand on trouve l'instruction, rajouter les déclarations*)
                
                decl_ram := !decl_ram^"unsigned long long "^name^"[1ULL<<"^(string_of_int addr_size)^"];\n for (unsigned long long iiiii=0; iiiii < (1ULL << ("^(string_of_int addr_size)^"));iiiii++){\n"^name^"[iiiii] = 0;};\n";
                (*let start_pos = "("^(arg_to_s write_addr)^" * "^(string_of_int word_size)^")" in
                let val_b = "(write_ram(ram_data,"^(start_pos)^","^start_pos^"+"^(string_of_int (word_size))^","^(arg_to_s write_data)^","^(arg_to_s we)^"));\n" in*) (*Encore un héritage d'une époque révolue*)
                let val_b = name^"["^(arg_to_s write_addr)^"] = "^" ("^(arg_to_s we)^"&1) ? "^(arg_to_s write_data)^" : "^name^"["^(arg_to_s write_addr)^"]"^";\n" in
                action := !action @ [TrucEnTrop val_b]; add_action_write_ram q in

  add_action_write_ram !ram_delay;
  
  
  (*let write_ram_str = "write_ram_file (ram_data);\n" in
  action := !action @ [TrucEnTrop write_ram_str];*) (*Heritage d'une ancienne époque*)


  let upgarde_end_reg x = (Hashtbl.find name x)^"_reg_version"^" = "^(Hashtbl.find name x)^";\n" in
  let rec add_action_reg_end l = 
      match l with
      |[] -> ()
      |t::q -> action := !action @ ([RegUpgradeEndCycle t]); add_action_reg_end q in
    action := !action @ [Jump];
    add_action_reg_end (list_keys p.p_vars);

  let rec add_action_print_output l = match l with 
      |[] -> ()
      |t::q -> let size = match (Env.find t p.p_vars) with |TBitArray n -> n |_ -> 1 in action := !action @ [PrintVar (t,size)]; add_action_print_output q in
  action := !action @ [Jump];
  add_action_print_output p.p_outputs;
  
  let rec evolve_code l = 
    match l with 
    |[] -> ""
    |(IntMain)::q -> ("int main()\n{\n") ^ (evolve_code q) ^ ("return 0;\n}\n")
    |(VarDeclare x):: q -> (get_string_declaration x) ^ "\n" ^ (evolve_code q)
    |(VarAssign (a,b))::q -> (Hashtbl.find name a)^" = "^b^(evolve_code q)
    |(For n)::q -> (!decl_ram)^("\nfor (int number_steps=0; number_steps < "^(string_of_int n)^"; number_steps ++){\n") ^ (evolve_code q) ^ "}\n" (*inclure ici la déclaration des tableaus pour les RAM*)
    |(RegUpgradeEndCycle x)::q -> (upgarde_end_reg x)^(evolve_code q)
    |(Jump)::q -> "\n"^(evolve_code q)
    |(PrintVar (x,i))::q -> "printBoolArray("^(Hashtbl.find name x)^","^(string_of_int i)^",\""^(Hashtbl.find name x)^"\");\n"^(evolve_code q)
    |(InputVar (x,size))::q -> (Hashtbl.find name x)^" = read_binary("^(string_of_int size)^",\""^(Hashtbl.find name x)^"\");\n"^(evolve_code q)
    |(TrucEnTrop s)::q -> s^(evolve_code q) in

  
  code := !code ^ (evolve_code !action);

  

  let replace_suffix str = ((String.sub str 0 (String.length str - 4)) ^ ".c") in  
  let out_channel = open_out (replace_suffix path) in
  output_string out_channel !code;
  close_out out_channel
  

  













let simulator program number_steps= 

  let initialize_ram filename size =
    let out_channel = open_out filename in  
    output_string out_channel (String.make size '0'); 
    close_out out_channel in 
  
  
  initialize_ram ram_path ram_size;
  let p = Scheduler.schedule (program) in

  let s_to_ar y = 
    let tab = Array.make (String.length y) true in
    for i=0 to ((String.length y) - 1)
      do
      if (y.[i] = '0') then (tab.(i) <- false) 
      else (if (y.[i] != '1') then (raise InputProblem))
  done;
  tab in

  let read_ram_file filename =
    let in_channel = open_in filename in
    let ram = input_line in_channel in
    close_in in_channel;
    ram in

  let ram_act = ref (read_ram_file ram_path) in
  let rom = (read_ram_file rom_path) in
   
  
  let write_ram addr_size word_size write_addr write_data =
    if ((String.length write_data) != word_size) then raise (NetlistError "La taille des données à écrire ne correspond pas à la taille du mot.")
    else (
      let start_pos = if cases_memoire then write_addr * word_size else write_addr in
      let len = String.length !ram_act in
      let new_ram = (String.sub !ram_act 0 start_pos) ^ write_data ^ (String.sub !ram_act (start_pos + word_size) (len - start_pos - word_size)) in
      ram_act := new_ram
    ) in

    
    
    let write_ram_file filename ram =
      let out_channel = open_out filename in
      output_string out_channel ram;
      close_out out_channel in
  
  let word_to_v x w =
    match (Env.find x p.p_vars) with 
    |TBit -> if (w = "0") then (VBit false) else (VBit true)
    |TBitArray n -> let a = s_to_ar w in if (n = Array.length a) then (VBitArray a) else (raise (NetlistError "Le mot sélectionné dans la ram n'a pas la bonne taille pour ce VBit Array")) in

  let scan_string () = Scanf.scanf " %s" (fun x -> x) in

  let rec read v = 
    Printf.printf "%s ? " v;
    flush stdout;
    let t = scan_string () in
    let attend = match (Env.find v p.p_vars) with
      |TBit -> 1
      |TBitArray n -> n in
    if (String.length t) != attend then 
      (Printf.printf "Wrong input :( \n%!";
      read v;)
  else (if (match (Env.find v p.p_vars) with |TBit -> true |_ -> false) then 
      if t = "1" then (VBit true) else (if  t = "0" then (VBit false) else (Printf.printf "Wrong input :( \n%!"; read v))
    else 
      try (VBitArray (s_to_ar t)) with |InputProblem -> Printf.printf "Wrong input :( \n%!"; read v )in
  
  let env_prec = ref (Hashtbl.create 1) in
  

  for i=1 to (number_steps) do 
    
    
  let ram_reading = read_ram_file ram_path in


  let read_ram addr_size word_size read_addr =
    let start_pos = if cases_memoire then read_addr * word_size else read_addr in
    let word = String.sub (ram_reading) start_pos word_size in word in

  let read_rom addr_size word_size read_addr =
    let start_pos = if cases_memoire then read_addr * word_size else read_addr in
    let word = String.sub (rom) start_pos word_size in word in
  
    
    let env = Hashtbl.create 1000 in
    
    let rec inputing l_in = 
      match l_in with 
      |[] -> ()
      |t::q -> Hashtbl.replace env t (read t); inputing q in


    let list_keys env =
      Env.fold (fun key _ acc -> key :: acc) env [] in


    (* A Appliquer sur la liste des clés*)
    let rec initializing_variable l = match l with 
      |[] -> ()
      |t::q -> (match (Env.find t p.p_vars) with 
        |TBit -> Hashtbl.replace env t (VBit true)
        |TBitArray n -> Hashtbl.replace env t (VBitArray (Array.make n true)) ); initializing_variable q in 

    

    let get_arg argu = match argu with
    |Aconst v -> v
    |Avar x -> Hashtbl.find env x in

    let bnot valu = 
      match valu with 
      |VBit o -> VBit (not o)
      |VBitArray tab -> let n = Array.length tab in  
                        (for i=0 to (n-1) 
                          do 
                          (tab.(i) <- (not tab.(i)))
                        done; VBitArray tab) in

        
    let binop op v1 v2 = 
      let fonct =
      match op with 
        |Or -> let f a b = a || b in f
        |Xor -> let f a b = (a || b) && (not (a && b)) in f
        |And -> let f a b = a && b in f
        |Nand -> let f a b = not (a && b) in f in

      match v1, v2 with 
      |VBit o1, VBit o2 -> VBit (fonct o1 o2)
      |VBitArray t1, VBitArray t2 when ((Array.length t1)=(Array.length t2))-> 
        let n = Array.length t1 in
        let tab = Array.make n true in
          (for i=0 to (n-1) 
          do 
          (tab.(i) <- (fonct t1.(i) t2.(i)))
        done; VBitArray tab) 
      |VBit o1, VBitArray t2 -> 
        let n = Array.length t2 in
        let tab = Array.make n true in
        (for i=0 to (n-1) do 
          (tab.(i) <- (fonct t2.(i) o1))
        done; VBitArray tab)
      |VBitArray t2, VBit o1 -> 
        let n = Array.length t2 in
        let tab = Array.make n true in
        (for i=0 to (n-1) do 
          (tab.(i) <- (fonct t2.(i) o1))
        done; VBitArray tab)
      |_ -> raise (NetlistError "Pas possible de faire cette opération ici") in

    let rec mux a b c =
      match a with 
      |VBit aa when (aa) -> c
      |VBit _ -> b
      |VBitArray aa when (Array.length aa) = 1 -> mux (VBit (aa.(0))) b c
      |_ -> raise (NetlistError "Le choix du mux doit être de taille 1") in

    let rec concat aa bb  = 
      match aa,bb with
      |VBit a, _ -> concat (VBitArray [|a|]) bb
      |_, VBit b -> concat aa (VBitArray [|b|])
      |VBitArray a, VBitArray b -> let n = Array.length a in let m = Array.length b in let c = Array.make (n+m) true in
        for i=0 to (n-1) do
          c.(i) <- a.(i);
        done;
        for i=0 to m-1 do
           c.(i+n) <- b.(i);
        done;
        VBitArray c in
    let select i aa =
      match aa with 
      |VBitArray a -> VBit a.(i)
      |_ -> raise (NetlistError "On doit avoir des VBitArray pour faire de la sélection") in

    let slice i j aa = 
      (match aa with
      |VBitArray a -> let n = Array.length a in 
        if ((i > j) || (j > n)) then raise (NetlistError "Les données d'entrées ne sont pas possibles (la tranche demandée n'est pas incluse dans le VBitArray ou la tranche n'existe pas)")
        else (
        let c = Array.make (j - i + 1) true in
        for k=0 to (j-i+1-1) do
          c.(k) <- a.(k+i);
        done;
        VBitArray c 
        )
      |_ -> raise (NetlistError "On doit avoir des VBitArray pour faire des slices"))in


      let v_to_int v =
        match v with
        |VBit b -> if b then 1 else 0
        |VBitArray arr -> Array.fold_left (let f acc b = (acc lsl 1) + if b then 1 else 0 in f) 0 arr in

        
      let v_to_string v =
        match v with
        |VBit b -> if b then "1" else "0"  
        |VBitArray arr -> Array.fold_left (let f acc b = acc ^ (if b then "1" else "0") in f) "" arr in
      
  
      (*let op_to_string op = (match op with 
      |Or -> "OR" 
      |Xor -> "XOR" 
      |And -> "AND"
      |Nand -> "NAND") in*)

      let ram_delay = ref [] in 

      let rec doing equ =
        match equ with
        | (x, Earg argu) -> 
            let value_ = get_arg argu in
            Hashtbl.replace env x value_;
            
        | (x, Ereg argu) -> 
            let value_ = (try 
                          (Hashtbl.find (!env_prec) (argu));
                        with 
                        | Not_found -> VBit false) in
            Hashtbl.replace env x value_;
            
        | (x, Enot argu) -> 
            let value_ = bnot (get_arg argu) in
            Hashtbl.replace env x value_;
            
        | (x, Ebinop (op, a1, a2)) -> 
            let val_a1 = get_arg a1 in
            let val_a2 = get_arg a2 in
            let result = binop op val_a1 val_a2 in
            Hashtbl.replace env x result;
            
        | (x, Emux (a, b, c)) -> 
            let val_a = get_arg a in
            let val_b = get_arg b in
            let val_c = get_arg c in
            let result = mux val_a val_b val_c in
            Hashtbl.replace env x result;
            
        | (x, Econcat (a, b)) -> 
            let val_a = get_arg a in
            let val_b = get_arg b in
            let result = concat val_a val_b in
            Hashtbl.replace env x result;
            
        | (x, Eselect (i, a)) -> 
            let val_a = get_arg a in
            let result = select i val_a in
            Hashtbl.replace env x result;
            
        | (x, Eslice (i, j, a)) -> 
            let val_a = get_arg a in
            Hashtbl.replace env x (slice i j val_a);
            
        | (x, Eram (addr_size, word_size, read_addr, write_enable, write_addr, write_data)) 
            when (match (get_arg write_enable) with | VBit a -> a | _ -> false) -> 
                let read_value = read_ram addr_size word_size (v_to_int (get_arg read_addr)) in
                (*write_ram addr_size word_size (v_to_int (get_arg write_addr)) (v_to_string (get_arg write_data));*)
                ram_delay := (addr_size, word_size, (v_to_int (get_arg write_addr)),(v_to_string (get_arg write_data)))::(!ram_delay);
                Hashtbl.replace env x (word_to_v x read_value);
            
        | (x, Eram (addr_size, word_size, read_addr, write_enable, write_addr, write_data)) -> 
                let read_value = read_ram addr_size word_size (v_to_int (get_arg read_addr)) in
                Hashtbl.replace env x (word_to_v x read_value);

        | (x, Erom (addr_size, word_size, read_addr)) -> 
                if debug then Printf.printf "Instruction rom n°%d\n" ((v_to_int (get_arg read_addr)) / 32 + 1);
                let read_value = read_rom addr_size word_size (v_to_int (get_arg read_addr)) in
                Hashtbl.replace env x (word_to_v x read_value) in      
      
            

      let copy_hashtbl original =
        let new_table = Hashtbl.create (Hashtbl.length original) in
        Hashtbl.iter (fun key value_ -> Hashtbl.add new_table key value_) original;
        new_table in

      
    let rec ram_delay_do l = match l with 
    |[] -> ()
    |(addr_size,word_size,wa,wd)::q-> write_ram addr_size word_size wa wd; ram_delay_do q in


    (*A appliquer sur les outputs*)
    let rec print_var l = 
      match l with
      |[] -> ()
      |t::q -> Printf.printf "%s = %s\n" t (v_to_string (Hashtbl.find env t)); print_var q in 
      
      
      (*let rec print_var2 l = 
        match l with
        |[] -> ()
        |t::q -> Printf.printf "%s = %s\n" t (val_to_s (Hashtbl.find !env_prec t)); print_var2 q in*)
      
    initializing_variable (list_keys p.p_vars);
    inputing p.p_inputs;
    (*print_var (list_keys p.p_vars);*)
    List.iteri (fun i eq -> 
      try
        doing eq;
        if debug then (let x = fst eq in
        let value = Hashtbl.find env x in
        let condition = not (String.starts_with ~prefix:"_l_" x) in
        let condition = condition && x = "jnz" in
        if condition then 
          Printf.printf "%s = %s\n" x (v_to_string value));
      with NetlistError s -> failwith ("Ligne "^(string_of_int (i+1))^" : "^s)) (p.p_eqs);
    ram_delay_do !ram_delay;
    write_ram_file ram_path !ram_act;
    print_var p.p_outputs;
    (*print_var (list_keys p.p_vars);*)
    env_prec := copy_hashtbl env;
    if debug then Printf.printf "\n";
done  

let compile filename =
  try
    let p = Netlist.read_file filename in
    begin try
        let p = Scheduler.schedule p in
        if !activate_c then (write_c p !number_steps filename) else
        simulator p !number_steps
      with
        | Scheduler.Combinational_cycle ->
            Format.eprintf "The netlist has a combinatory cycle.@.";
    end;
  with
    | Netlist.Parse_error s -> Format.eprintf "An error accurred: %s@." s; exit 2

let main () =
  Arg.parse
    ["-n", Arg.Set_int number_steps, "Number of steps to simulate";
     "-c", Arg.Set activate_c, "Activer l'écriture d'un fichier c pour le simulateur"]
    compile
    ""
;;

main ()
