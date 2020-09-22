const MEDIA_SERVICE = "http://localhost:4004/streaming/Media";

document.onload = () => {};

document
  .getElementById("upload-form")
  .addEventListener("submit", async (event) => {
    event.preventDefault();
    const file = document.getElementById("file-input").files[0];
    const data = await createMedia();
    uploadFile(file, data.ID);
  });

// create media record ind db
function createMedia() {
  return new Promise((res) => {
    const xhr = new XMLHttpRequest();
    xhr.open("POST", MEDIA_SERVICE, true);
    xhr.setRequestHeader("Content-Type", "application/json");
    xhr.onreadystatechange = function () {
      if (this.readyState === XMLHttpRequest.DONE && this.status === 201) {
        console.log("Media created");
        res(JSON.parse(this.response));
      } else if (
        this.readyState === XMLHttpRequest.DONE &&
        this.status !== 201
      ) {
        throw new Error();
      }
    };
    // xhr.send(JSON.stringify({ mediaType: "video/mp4" }));
    xhr.send(JSON.stringify({}));
  });
}

// update media with content
function uploadFile(file, ID) {
  return new Promise((res, rej) => {
    const xhr = new XMLHttpRequest();
    xhr.upload.addEventListener(
      "progress",
      (event) => {
        if (event.lengthComputable) {
          const percentage = Math.round((event.loaded * 100) / event.total);
          console.log("[UPLOADING PROGRESS]", percentage);
        }
      },
      false
    );
    xhr.upload.addEventListener(
      "load",
      function () {
        console.log("[UPLOADING PROCESS COMPLETED]", 100);
        res();
      },
      false
    );
    xhr.open("PUT", `${MEDIA_SERVICE}(${ID})/media`);
    xhr.setRequestHeader("Content-Type", "video/mp4");

    const reader = new FileReader();
    reader.onload = function (event) {
      xhr.send(event.target.result);
    };
    reader.readAsBinaryString(file);
  });
}
