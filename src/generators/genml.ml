(*
 * Copyright (C)2005-2018 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *)

open Globals
open Ast
open Type
open Common

type ctx = {
	com : Common.context;
	mutable ch : out_channel;
	dirs : (string list, bool) Hashtbl.t;
}

let begin_module ctx (path,name) =
	if not (Hashtbl.mem ctx.dirs path) then begin
		Path.mkdir_recursive ctx.com.file path;
		Hashtbl.add ctx.dirs path true;
	end;
	let file = ctx.com.file ^ (match path with [] -> "" | _ -> "/" ^ String.concat "/" path) ^ "/" ^ name ^ ".ml" in
	ctx.ch <- open_out_bin file

let end_module ctx =
	close_out ctx.ch;
	ctx.ch <- stdout

let generate_class ctx c =
	()

let generate_type ctx t =
	match t with
	| TClassDecl { cl_extern = true } ->
		()
	| TClassDecl c ->
		begin_module ctx c.cl_path;
		generate_class ctx c;
		end_module ctx;
	| TAbstractDecl { a_impl = None } ->
		() (* core type *)
	| TTypeDecl td ->
		begin_module ctx td.t_path;
		end_module ctx;
	| _ ->
		abort "Unsupported module type"  (t_infos t).mt_pos

let generate com =
	let ctx = {
		com = com;
		ch = stdout;
		dirs = Hashtbl.create 0;
	} in
	(try Unix.mkdir ctx.com.file 0o755 with _ -> ());
	List.iter (generate_type ctx) com.types
