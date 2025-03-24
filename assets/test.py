from ultralytics import YOLO

model = YOLO("best.pt")
model.predict(source = "5.jpeg", show= True, save=True)