defmodule Mix.Project do

   def project do
     [project: "Xonad", version: "0.1", 
     compile_options: [ignore_module_conflict: true, docs: true]]
   end

   def application, do: []

end
