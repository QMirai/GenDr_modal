// Author: François Lareau, Université de Montréal

// This MATE script takes as input a .str file that contains
// one or more semantic structure(s). It loops through them
// and applies a grammar to produce all possible outputs. For
// each input structure, a separate output file is produced,
// each file containing one or more output structure(s).

// TODO: loop through list

// Avoid useless output to console
console_output off;
echo off;

// PARAMETERS
// Get values of "-D" parameters passed at command line:
// -Dencoding  : character encoding (default "UTF-8")
// -Droot      : path to GenDR's root directory
// -Dlng       : ISO code for the language to use (default "eng")
// -Dlngpath   : path to the directory containing all language packs ("lng")
// -Dstrpath   : path to the test structures (default "<LNGPATH>/<LNG>/str/test")
// -Dstrname   : filename radical for input and output structures (default "test")
// -Dgraphs    : graphic output format (default "false", other options "jpg" or "svg")

enc := property("encoding");
if enc = "null" then
  enc := "UTF-8";
end if

root := property("root") + "/";

print(root);

lng := property("lng");
if lng = "null" then
  lng := "eng";
end if

lngpath := property("lngpath") + "/";
if lngpath = "null/" then
  lngpath := root+"lng/";
end if

strpath := property("strpath") + "/";
if strpath = "null/" then
  strpath := lngpath + lng + "/str/test/eval/";
end if

strname := property("strname");
if strname = "null" then
  strname := "test";
end if

graphs := property("graphs");
if graphs = "null" then
  graphs := "svg";
//  graphs := "jpg";
end if

print("");
print("Running test script with parameters:");
print("  enc     "+enc);
print("  root    "+root);
print("  lng     "+lng);
print("  lngpath "+lngpath);
print("  strpath "+strpath);
print("  strname "+strname);
print("  graphs  "+graphs);

exec := execute(); // don't ask, we need it for graphics export


// LOAD MODULES
// Load the Sem-DSynt module that contains the grammar rules
// TODO: Pass filenames as parameters

print("Loading module 1");
sem_dsynt := loadrules(lngpath+"core/", "20-sem-dsynt.rls");

print("Loading module 2");
dsynt_ssynt := loadrules(lngpath+"core/", "25-dsynt-ssynt.rls");

print("Loading module 3");
ssynt_ssynt := loadrules(lngpath+"core/", "26-ssynt-ssynt.rls");

print("Loading module 4");
ssynt_ssynt_treecheck := loadrules(lngpath+"core/", "27-ssynt-synt-treecheck.rls");


// LOAD DICTIONARIES
// Load four dictionaries:
// - LF in rsrcs/all directory, and language_info, semanticon and lexicon in rsrcs/lng directory
// TODO: Pass filenames as parameters

print("");
print("Loading dictionaries:");

print("  gpcon");
gp_lex  := loaddictionary(lngpath + lng + "/", "gpcon.dict");

print("  semanticon");
sem_lex := loaddictionary(lngpath + lng + "/", "semanticon.dict"); 

print("  lexicon");
lex_lex := loaddictionary(lngpath + lng + "/", "lexicon.dict");

print("  lf");
gp_lex  := loaddictionary(lngpath + "core/", "lf.dict");


// PROCESS

//save("", strpath, "results.txt", false, enc);       // initialize report
//msg := "Loading " + lng + " " + strname + "\r";
//save(msg, strpath, "results.txt", true, enc);

print("");
print("Loading input file: " + strname + ".sem.str");

strs_in := load(strpath, strname + ".sem.str");     // load input file
strs_in := parse(strs_in);                          // get list of structures it contains

print("Processing input structures");
i := 0;                                             // initialize index
for str_i in strs_in do                             // loop through all input structures
  i := i + 1;                                       // increment index
  print("");
  print("Input structure " + i);

  // we export input structures as graphics if enabled
  fname_i := strpath + strname+"-"+i + ".sem";      // filename for graphics (.svg/.jpg appended on export)
  if graphs = "svg" then                            // if SVG export is enabled
    x := exec.saveSVG(.str_i, .fname_i);            // export SVG file for input structure
  end if
  if graphs = "jpg" then                            // if JPG export is enabled
    x := exec.saveJPG(.str_i, .fname_i);            // export JPG file for input structure
  end if

  // apply the first module to the input structure
	print("  Applying module 1");
	str_i := str_i.asString();                            // convert structure to string representation
	strs_out := execute(sem_dsynt, str_i);                // apply Sem <=> DSynt rules

	// export the output structures as .str (and optionally SVG/JPG)
	fname := strname + "-" + i + ".dsynt.str";                  // prepare output filename
	// we want one .str file where we will write all output structures for input at index i
	save("", strpath, fname, false, enc);                 // initialize output file (false=overwrite)
	j := 0;                                               // initialize index
	for str_j in strs_out do                              // loop through all output structures
		j := j + 1;                                         // increment index
		fname_j := strpath + strname+"-"+i + ".dsynt"+j;    // filename for graphics (.svg/.jpg appended on export)
		// for graphics, we need to have only one output structure per file
		if graphs = "svg" then                              // if SVG export is enabled
			x := exec.saveSVG(.str_j, .fname_j);              // export SVG file for output structure
		end if
		if graphs = "jpg" then                              // if JPG export is enabled
			x := exec.saveJPG(.str_j, .fname_j);              // export JPG file for output structure
		end if
		str_j := str_j.asString();                          // convert structure to string representation
		save(str_j, strpath, fname, true, enc);             // append structure to file (true=append)

		// apply the second module to the output structure
		print("  Applying module 2");
		strs_out2 := execute(dsynt_ssynt, str_j);         // apply DSynt <=> SSynt rules

		// export the output structures as .str (and optionally SVG/JPG)
		fname2 := strname+"-"+ i + ".dsynt" + j + ".ssynt.str"; // prepare output filename
		// we want one .str file where we will write all output structures for input at index i.j
		save("", strpath, fname2, false, enc);            // initialize output file (false=overwrite)
		k := 0;                                           // initialize index
		for str_k in strs_out2 do                         // loop through all output structures
			k := k + 1;                                     // increment index
			fname_k := strpath+strname+"-"+i+".dsynt"+j+".ssynt"+k; // filename for graphics (.svg/.jpg appended on export)
			// for graphics, we need to have only one output structure per file
			if graphs = "svg" then                          // if SVG export is enabled
				x := exec.saveSVG(.str_k, .fname_k);          // export SVG file for output structure
			end if
			if graphs = "jpg" then                          // if JPG export is enabled
				x := exec.saveJPG(.str_k, .fname_k);          // export JPG file for output structure
			end if
			str_k := str_k.asString();                      // convert structure to string representation
			save(str_k, strpath, fname2, true, enc);        // append structure to file (true=append)
			
			// apply the third module to the output structure
			print("  Applying module 3");
			strs_out3 := execute(ssynt_ssynt, str_k);         // apply SSynt <=> SSynt rules

			// export the output structures as .str (and optionally SVG/JPG)
			fname3 := strname+"-"+ i + ".dsynt" + j + ".ssynt" + k + ".ssynt.str"; // prepare output filename
			// we want one .str file where we will write all output structures for input at index i.j.k
			save("", strpath, fname3, false, enc);            // initialize output file (false=overwrite)
			m := 0;                                           // initialize index
			for str_m in strs_out3 do                         // loop through all output structures
				m := m + 1;                                     // increment index
				fname_m := strpath+strname+"-"+i+".dsynt"+j+".ssynt"+k+".ssynt"+m; // filename for graphics (.svg/.jpg appended on export)
				// for graphics, we need to have only one output structure per file
				if graphs = "svg" then                          // if SVG export is enabled
					x := exec.saveSVG(.str_m, .fname_m);          // export SVG file for output structure
				end if
				if graphs = "jpg" then                          // if JPG export is enabled
					x := exec.saveJPG(.str_m, .fname_m);          // export JPG file for output structure
				end if
				str_m := str_m.asString();                      // convert structure to string representation
				save(str_m, strpath, fname3, true, enc);        // append structure to file (true=append)
				
				// apply the forth module to the output structure
				print("  Applying module 4");
				strs_out4 := execute(ssynt_ssynt_treecheck, str_m);         // apply SSynt <=> SSynt_treecheck rules

				// export the output structures as .str (and optionally SVG/JPG)
				fname4 := strname+"-"+ i + ".dsynt" + j + ".ssynt" + k + ".ssynt" + m + ".ssynt_treecheck.str"; // prepare output filename
				// we want one .str file where we will write all output structures for input at index i.j.k.m
				save("", strpath, fname4, false, enc);            // initialize output file (false=overwrite)
				n := 0;                                           // initialize index
				for str_n in strs_out4 do                         // loop through all output structures
					n := n + 1;                                     // increment index
					fname_n := strpath+strname+"-"+i+".dsynt"+j+".ssynt"+k+".ssynt"+m+".synt_treecheck"; // filename for graphics (.svg/.jpg appended on export)
					// for graphics, we need to have only one output structure per file
					if graphs = "svg" then                          // if SVG export is enabled
						x := exec.saveSVG(.str_n, .fname_n);          // export SVG file for output structure
					end if
					if graphs = "jpg" then                          // if JPG export is enabled
						x := exec.saveJPG(.str_n, .fname_n);          // export JPG file for output structure
					end if
					str_n := str_n.asString();                      // convert structure to string representation
					save(str_n, strpath, fname4, true, enc);        // append structure to file (true=append)
				next;
			next;
		next;                                             // end of loop through output structures k
	next;                                             // end of loop through output structures j
next;                                               // end of loop through input structures i

print("");
print("Done");
