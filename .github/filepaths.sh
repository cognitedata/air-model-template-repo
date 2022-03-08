#!/usr/bin/env bash

# Cases normal lists (done)
# Case inline list with brackets
# Case inline list with no brackets

# Variables and arrays needed

ignore_models=()
filepaths=()
repoconfig=()
counter=0
project_mapping=()
last_function=""

# Strings to add to final output string
base_string="{\"functionproject\":["
end_string="]}"

# Function to join
 join () {
  local IFS="$1"
  shift
  echo "$*"
}

# Function to read all models to be ignored
while read line || [ -n "$line" ]; do
  ignore_models+="$line"
done < ".ignore_models"


# Function to exclude all the models in ignored models
for f in $PWD/functions/*; do
  if [ -d "$f" ]; then
     if [[ " ${ignore_models[*]} " == *"$(basename $f)"* ]]; then
     echo ""
     else
     filepaths=(${filepaths[@]} "\"$(basename $f)\"")
     fi
  fi
done

if [ -z "$filepaths" ]; then
    echo "All models are ignored!"
fi

while read line || [ -n "$line" ]; do
  ig=$( echo "$line" |cut -d\# -f1 )
  if [ $counter == 1 ] && [ "${ig}" != "" ]; then
    repoconfig+=("$ig")
  elif [[ $ig == "ProjectFunctionMap:" ]]; then
    counter=1
  fi
done < "repoconfig.yaml"

for f in "${repoconfig[@]}"; do
  if [[ $f == *": ["*"]"* ]]; then
    last_function=$( echo "$f" |cut -d\: -f1 )
    project=$(echo $f | cut -d "[" -f2 | cut -d "]" -f1)
    IFS=', ' read -r -a array <<< "$project"
    for element in "${array[@]}"
    do
    refined_project=$(echo $element | cut -d "\"" -f2 | cut -d "\"" -f1)
    mapped="\"${last_function}@${refined_project}\""
    project_mapping+=("$mapped")
    done
  elif [[ $f == *":" ]]; then
  # if colon is in line and there is no paranthesis it is a function
    # remove colon from string
    # store it in last_function
    last_function=$( echo "$f" |cut -d\: -f1 )
  elif [[ $f == *": "* ]]; then
  # if colon is in line but there is a paranthesis it is an inline list
    # remove colon from string
    # store project and function seperately
    last_function=$( echo "$f" |cut -d\: -f1 )
    project=$( echo "$f" |cut -d \: -f2 | cut -d " " -f2 )
    refined_project=$(echo $project | cut -d "\"" -f2 | cut -d "\"" -f1)
    mapped="\"${last_function}@${refined_project}\""
    project_mapping+=("$mapped")
  else
  # else (not it is a project)
    # remove '- ' part from string
    # glue last_function with @ and string
    # add to project_mapping
    project=${f:2}
    mapped="\"${last_function}@${project}\""
    project_mapping+=("$mapped")
  fi
done

com_sep_paths1="$(join , "${filepaths[@]}")"
com_sep_paths2="$(join , "${project_mapping[@]}")"
#
#
final_string=$base_string$com_sep_paths2$end_string
echo "::set-output name=matrix::$final_string"